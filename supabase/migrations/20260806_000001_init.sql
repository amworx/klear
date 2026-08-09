-- Klear: initial schema + row-level security (RLS)
-- Run in the Supabase SQL editor (or `supabase db push`).
-- PostgreSQL. Arabic text handled via UTF-8 (any collation).

-- ============================================================
-- 1) PROFILES (extends auth.users) — must come BEFORE functions
-- ============================================================
create table if not exists public.profiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  full_name   text,
  phone       text unique,
  role        text not null default 'customer'
              check (role in ('customer', 'provider', 'admin')),
  is_available boolean not null default false, -- used by providers
  created_at  timestamptz not null default now()
);

alter table public.profiles enable row level security;

-- A user can read/update only their own profile.
drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own" on public.profiles
  for select using (auth.uid() = id);
drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own" on public.profiles
  for insert with check (auth.uid() = id);
drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own" on public.profiles
  for update using (auth.uid() = id);

-- ============================================================
-- 2) HELPER FUNCTIONS (defined after profiles table exists)
-- ============================================================
create or replace function public.is_admin() returns boolean
  language sql stable security definer as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

create or replace function public.is_provider() returns boolean
  language sql stable security definer as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'provider'
  );
$$;

-- Backfill: keep updated_at fresh on booking edits.
create or replace function public.touch_updated_at() returns trigger
  language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

-- ============================================================
-- 3) SERVICES  (readable by everyone; managed by admin)
-- ============================================================
create table if not exists public.services (
  id        uuid primary key default gen_random_uuid(),
  name_ar   text not null,
  name_en   text not null,
  desc_ar   text,
  desc_en   text,
  base_price numeric(10, 2) not null default 0,
  currency  text not null default 'SYP',
  is_active boolean not null default true,
  sort      int not null default 0
);

alter table public.services enable row level security;

-- Catalog is public (both anonymous and authed users may list services).
drop policy if exists "services_select_public" on public.services;
create policy "services_select_public" on public.services
  for select using (true);
-- Management writes restricted to admin role.
drop policy if exists "services_admin_write" on public.services;
create policy "services_admin_write" on public.services
  for insert with check (public.is_admin());
drop policy if exists "services_admin_update" on public.services;
create policy "services_admin_update" on public.services
  for update using (public.is_admin());

-- ============================================================
-- 4) BOOKINGS
-- ============================================================
do $$ begin
  create type booking_status as enum
    ('pending', 'accepted', 'in_progress', 'completed', 'cancelled');
exception when duplicate_object then null;
end $$;

create table if not exists public.bookings (
  id            uuid primary key default gen_random_uuid(),
  customer_id   uuid not null references public.profiles (id),
  provider_id   uuid references public.profiles (id),
  service_id    uuid not null references public.services (id),
  status        booking_status not null default 'pending',
  scheduled_at  timestamptz not null,
  address       text,
  lat           double precision,
  lng           double precision,
  note          text,
  total_price   numeric(10, 2),
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create index if not exists bookings_customer_idx on public.bookings (customer_id);
create index if not exists bookings_provider_idx on public.bookings (provider_id);
create index if not exists bookings_status_idx on public.bookings (status);

alter table public.bookings enable row level security;

-- Customers see orders they created.
drop policy if exists "bookings_select_customer" on public.bookings;
create policy "bookings_select_customer" on public.bookings
  for select using (auth.uid() = customer_id);
drop policy if exists "bookings_insert_customer" on public.bookings;
create policy "bookings_insert_customer" on public.bookings
  for insert with check (auth.uid() = customer_id);
drop policy if exists "bookings_update_customer" on public.bookings;
create policy "bookings_update_customer" on public.bookings
  for update using (auth.uid() = customer_id);

-- Providers see jobs assigned to them.
drop policy if exists "bookings_select_provider" on public.bookings;
create policy "bookings_select_provider" on public.bookings
  for select using (public.is_provider() and provider_id = auth.uid());

-- ============================================================
-- 5) PAYMENTS
-- ============================================================
create table if not exists public.payments (
  id          uuid primary key default gen_random_uuid(),
  booking_id  uuid not null references public.bookings (id) on delete cascade,
  method      text not null,            -- e.g. 'card', 'cash', 'wallet'
  amount      numeric(10, 2) not null,
  status      text not null default 'pending'
              check (status in ('pending', 'paid', 'failed', 'refunded')),
  reference   text,                     -- external gateway reference
  created_at  timestamptz not null default now()
);

alter table public.payments enable row level security;

-- Customer owns their payment rows (via the booking).
drop policy if exists "payments_select_owner" on public.payments;
create policy "payments_select_owner" on public.payments
  for select using (
    exists (select 1 from public.bookings b
            where b.id = payments.booking_id and b.customer_id = auth.uid())
  );
drop policy if exists "payments_insert_owner" on public.payments;
create policy "payments_insert_owner" on public.payments
  for insert with check (
    exists (select 1 from public.bookings b
            where b.id = payments.booking_id and b.customer_id = auth.uid())
  );

-- ============================================================
-- 6) TRIGGER (uses helper defined in section 2)
-- ============================================================
drop trigger if exists bookings_touch_updated_at on public.bookings;
create trigger bookings_touch_updated_at before update on public.bookings
  for each row execute function public.touch_updated_at();
