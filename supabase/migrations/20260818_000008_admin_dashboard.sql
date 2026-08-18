-- Klear: P10 — Admin dashboard foundation.
--
-- 1) `app_settings`: single-row pricing/operations configuration (car-size
--    factors, urgent surcharge %, service hours, currency). The Flutter client
--    reads these for live estimates; admins edit them from the web dashboard.
-- 2) `profiles.is_active`: block/unblock users from the admin dashboard.
-- 3) Admin RLS policies: admins (via public.is_admin()) get full read + the
--    write rights the dashboard needs. Permissive policies OR together, so
--    existing owner policies remain untouched.

-- ============================================================
-- 1) APP SETTINGS (single-row)
-- ============================================================
create table if not exists public.app_settings (
  id int primary key default 1 check (id = 1),
  size_small_factor   numeric(10, 4) not null default 1.0,
  size_medium_factor  numeric(10, 4) not null default 1.25,
  size_large_factor   numeric(10, 4) not null default 1.5,
  urgent_surcharge_pct numeric(10, 4) not null default 25.0,
  service_hours_start time not null default '08:00',
  service_hours_end   time not null default '18:00',
  currency            text not null default 'SYP',
  updated_at          timestamptz not null default now()
);

insert into public.app_settings (id) values (1)
on conflict (id) do nothing;

alter table public.app_settings enable row level security;

-- Public read: the client app needs factors to estimate prices.
drop policy if exists "app_settings_select_public" on public.app_settings;
create policy "app_settings_select_public" on public.app_settings
  for select using (true);

-- Admin-only update.
drop policy if exists "app_settings_update_admin" on public.app_settings;
create policy "app_settings_update_admin" on public.app_settings
  for update using (public.is_admin()) with check (public.is_admin());

-- ============================================================
-- 2) PROFILES IS_ACTIVE (block/unblock)
-- ============================================================
alter table public.profiles
  add column if not exists is_active boolean not null default true;

-- ============================================================
-- 3) ADMIN RLS POLICIES
-- ============================================================

-- bookings: admins see and update all bookings (status, provider assignment).
drop policy if exists "bookings_select_admin" on public.bookings;
create policy "bookings_select_admin" on public.bookings
  for select using (public.is_admin());
drop policy if exists "bookings_update_admin" on public.bookings;
create policy "bookings_update_admin" on public.bookings
  for update using (public.is_admin()) with check (public.is_admin());

-- services: public select stays; admins manage the catalog.
drop policy if exists "services_insert_admin" on public.services;
create policy "services_insert_admin" on public.services
  for insert with check (public.is_admin());
drop policy if exists "services_update_admin" on public.services;
create policy "services_update_admin" on public.services
  for update using (public.is_admin()) with check (public.is_admin());
drop policy if exists "services_delete_admin" on public.services;
create policy "services_delete_admin" on public.services
  for delete using (public.is_admin());

-- profiles: admins read all + update all (name, phone, role, is_active).
drop policy if exists "profiles_select_admin" on public.profiles;
create policy "profiles_select_admin" on public.profiles
  for select using (public.is_admin());
drop policy if exists "profiles_update_admin" on public.profiles;
create policy "profiles_update_admin" on public.profiles
  for update using (public.is_admin()) with check (public.is_admin());

-- cars: admins read all (needed for client details / booking car info).
drop policy if exists "cars_select_admin" on public.cars;
create policy "cars_select_admin" on public.cars
  for select using (public.is_admin());

-- user_addresses: admins read all.
drop policy if exists "user_addresses_select_admin" on public.user_addresses;
create policy "user_addresses_select_admin" on public.user_addresses
  for select using (public.is_admin());

-- payments: admins read all + update status (mark paid/refunded).
drop policy if exists "payments_select_admin" on public.payments;
create policy "payments_select_admin" on public.payments
  for select using (public.is_admin());
drop policy if exists "payments_update_admin" on public.payments;
create policy "payments_update_admin" on public.payments
  for update using (public.is_admin()) with check (public.is_admin());
