-- Klear: Dynamic car attributes (admin-managed catalog).
--
-- The `cars` table only has fixed columns: make/model/plate_number/size, and
-- the client form hardcodes exactly those four fields. Admins have no control
-- over that set. This migration introduces an admin-managed attribute catalog:
--
-- 1) `car_attributes` — one row per car attribute. Fields: localized label
--    (ar+en), data type (`text` or `select`), optional select `options`,
--    display order, visibility (show/hide in the client), required flag, and
--    `is_system` to lock the built-in attributes so they cannot be deleted.
--    The four current fields are seeded as system attributes.
-- 2) `car_attribute_values` — per-car values. UNIQUE(car_id, attribute_id).
--    The three legacy columns (make/model/plate_number) continue to store the
--    values of their matching system attributes (zero breakage for existing
--    clients / booking code); any NEW attribute the admin adds becomes dynamic
--    and its values live here.
--
-- ============================================================
-- PRICING DRIVERS
-- ============================================================
-- Car attributes do NOT only describe the vehicle — some drive the service
-- price. `size` already does (its per-option factors live in `app_settings`:
-- size_small/medium/large_factor and multiply the service base price). So the
-- catalog supports price-affecting attributes generically:
--   * `affects_price` marks an attribute as a pricing driver.
--   * `price_factor` is the factor for `text` attributes (or a fallback).
--   * For `select` attributes, each option may carry its own `factor` in the
--     `options` JSONB.
-- The client price estimate = base_price × Π(factor of every price-affecting
-- attribute that has a value).
--
-- The reserved `size` attribute keeps reading its factor from `app_settings`
-- (single source of truth, already admin-editable on the Pricing page). Its
-- catalog options carry factors mirroring app_settings purely as metadata, so
-- the admin sees that size drives price; the client always resolves the actual
-- size factor from app_settings, never from the catalog. New custom
-- price-affecting attributes resolve their factors from their catalog options.

-- ============================================================
-- 1) CAR ATTRIBUTES (catalog)
-- ============================================================
create table if not exists public.car_attributes (
  id           uuid primary key default gen_random_uuid(),
  -- Stable lookup key: the system attributes use make/model/plate_number/size
  -- so they map onto the legacy `cars` columns / `app_settings`; custom
  -- attributes use any unique slug.
  key          text not null unique,
  label_ar     text not null,
  label_en     text not null,
  data_type    text not null default 'text'
               check (data_type in ('text', 'select')),
  -- For `select` attributes:
  --   [{ "value": "...", "label_ar": "...", "label_en": "...", "factor": 1.0 }]
  options      jsonb not null default '[]'::jsonb,
  -- Pricing driver: inclusion in the price estimate multiplier chain.
  affects_price boolean not null default false,
  -- Numeric multiplier for `text` attributes (or global fallback).
  price_factor numeric(10, 4) not null default 1.0,
  sort_order   int  not null default 0,
  is_visible   boolean not null default true,
  is_required  boolean not null default false,
  is_system    boolean not null default false,
  created_at   timestamptz not null default now()
);

alter table public.car_attributes enable row level security;

-- The client app renders the catalog to build the car form / list and to read
-- price factors, so select must be public. Admin manages the catalog.
drop policy if exists "car_attributes_select_public" on public.car_attributes;
create policy "car_attributes_select_public" on public.car_attributes
  for select using (true);

drop policy if exists "car_attributes_insert_admin" on public.car_attributes;
create policy "car_attributes_insert_admin" on public.car_attributes
  for insert with check (public.is_admin());

drop policy if exists "car_attributes_update_admin" on public.car_attributes;
create policy "car_attributes_update_admin" on public.car_attributes
  for update using (public.is_admin()) with check (public.is_admin());

drop policy if exists "car_attributes_delete_admin" on public.car_attributes;
create policy "car_attributes_delete_admin" on public.car_attributes
  for delete using (public.is_admin());

-- ============================================================
-- 2) CAR ATTRIBUTE VALUES (per-car)
-- ============================================================
create table if not exists public.car_attribute_values (
  id           uuid primary key default gen_random_uuid(),
  car_id       uuid not null references public.cars (id) on delete cascade,
  attribute_id uuid not null references public.car_attributes (id) on delete cascade,
  value        text not null,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  unique (car_id, attribute_id)
);

create index if not exists car_attribute_values_car_idx
  on public.car_attribute_values (car_id);
create index if not exists car_attribute_values_attr_idx
  on public.car_attribute_values (attribute_id);

alter table public.car_attribute_values enable row level security;

-- Owner of the car: full CRUD on their own values.
drop policy if exists "car_attribute_values_owner_select" on public.car_attribute_values;
create policy "car_attribute_values_owner_select" on public.car_attribute_values
  for select using (
    exists (
      select 1 from public.cars
      where cars.id = car_attribute_values.car_id and cars.user_id = auth.uid()
    )
  );

drop policy if exists "car_attribute_values_owner_insert" on public.car_attribute_values;
create policy "car_attribute_values_owner_insert" on public.car_attribute_values
  for insert with check (
    exists (
      select 1 from public.cars
      where cars.id = car_attribute_values.car_id and cars.user_id = auth.uid()
    )
  );

drop policy if exists "car_attribute_values_owner_update" on public.car_attribute_values;
create policy "car_attribute_values_owner_update" on public.car_attribute_values
  for update using (
    exists (
      select 1 from public.cars
      where cars.id = car_attribute_values.car_id and cars.user_id = auth.uid()
    )
  ) with check (
    exists (
      select 1 from public.cars
      where cars.id = car_attribute_values.car_id and cars.user_id = auth.uid()
    )
  );

drop policy if exists "car_attribute_values_owner_delete" on public.car_attribute_values;
create policy "car_attribute_values_owner_delete" on public.car_attribute_values
  for delete using (
    exists (
      select 1 from public.cars
      where cars.id = car_attribute_values.car_id and cars.user_id = auth.uid()
    )
  );

-- Admin: read all + manage.
drop policy if exists "car_attribute_values_select_admin" on public.car_attribute_values;
create policy "car_attribute_values_select_admin" on public.car_attribute_values
  for select using (public.is_admin());

drop policy if exists "car_attribute_values_insert_admin" on public.car_attribute_values;
create policy "car_attribute_values_insert_admin" on public.car_attribute_values
  for insert with check (public.is_admin());

drop policy if exists "car_attribute_values_update_admin" on public.car_attribute_values;
create policy "car_attribute_values_update_admin" on public.car_attribute_values
  for update using (public.is_admin()) with check (public.is_admin());

drop policy if exists "car_attribute_values_delete_admin" on public.car_attribute_values;
create policy "car_attribute_values_delete_admin" on public.car_attribute_values
  for delete using (public.is_admin());

-- Providers with an assigned (or open-pool pending) booking for that car can
-- read the values (e.g. to view a custom "color" or custom field), mirroring
-- the `cars_select_provider` policy on the cars table.
drop policy if exists "car_attribute_values_provider_select" on public.car_attribute_values;
create policy "car_attribute_values_provider_select" on public.car_attribute_values
  for select to authenticated
  using (
    exists (
      select 1
      from public.bookings b
      where b.car_id = car_attribute_values.car_id
        and (
          b.provider_id = auth.uid()
          or (b.status = 'pending' and b.provider_id is null)
        )
    )
  );

-- keep updated_at fresh on value edits
drop trigger if exists "car_attribute_values_touch_updated_at" on public.car_attribute_values;
create trigger car_attribute_values_touch_updated_at
  before update on public.car_attribute_values
  for each row execute procedure public.touch_updated_at();

-- ============================================================
-- 3) SEED: system attributes (the current fixed fields)
-- ============================================================
-- size options carry factors mirroring app_settings defaults (1.0 / 1.25 /
-- 1.5) as metadata; the client resolves the actual size factor from
-- app_settings so the Pricing page stays the single source of truth.
insert into public.car_attributes
  (key, label_ar, label_en, data_type, options, affects_price, price_factor, sort_order, is_visible, is_required, is_system)
values
  ('make', 'الماركة', 'Make (brand)', 'text', '[]'::jsonb, false, 1.0, 10, true, true, true),
  ('model', 'الطراز', 'Model', 'text', '[]'::jsonb, false, 1.0, 20, true, true, true),
  ('plate_number', 'رقم اللوحة', 'Plate number', 'text', '[]'::jsonb, false, 1.0, 30, true, true, true),
  ('size', 'حجم السيارة', 'Car size', 'select',
   '[{"value":"small","label_ar":"صغير","label_en":"Small","factor":1.0},
     {"value":"medium","label_ar":"متوسط","label_en":"Medium","factor":1.25},
     {"value":"large","label_ar":"كبير","label_en":"Large","factor":1.5}]'::jsonb,
   true, 1.0, 40, true, true, true)
on conflict (key) do nothing;
