-- Klear: P6 — user cars (with size-aware pricing), booking refs, service duration
--
-- 1) `cars`: users register their vehicles (make/model/plate/size) so the wash
--    team can identify them when the owner is absent and so the app can
--    estimate cost from the car size.
-- 2) `bookings.car_id`: link a booking to the user's car.
-- 3) `services.duration_min`: show expected duration on service cards.

-- ============================================================
-- 1) CARS
-- ============================================================
create table if not exists public.cars (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references auth.users (id) on delete cascade,
  make         text not null,
  model        text not null,
  plate_number text not null,
  size         text not null default 'medium'
               check (size in ('small', 'medium', 'large')),
  created_at   timestamptz not null default now(),
  unique (user_id, plate_number)
);

create index if not exists cars_user_idx on public.cars (user_id);

alter table public.cars enable row level security;

-- Owner can read/insert/update/delete only their own cars.
drop policy if exists "cars_select_own" on public.cars;
create policy "cars_select_own" on public.cars
  for select using (auth.uid() = user_id);
drop policy if exists "cars_insert_own" on public.cars;
create policy "cars_insert_own" on public.cars
  for insert with check (auth.uid() = user_id);
drop policy if exists "cars_update_own" on public.cars;
create policy "cars_update_own" on public.cars
  for update using (auth.uid() = user_id);
drop policy if exists "cars_delete_own" on public.cars;
create policy "cars_delete_own" on public.cars
  for delete using (auth.uid() = user_id);

-- Washing team (provider) can read the car of a booking assigned to them,
-- so they can identify the vehicle when the owner is not present.
drop policy if exists "cars_select_provider" on public.cars;
create policy "cars_select_provider" on public.cars
  for select using (
    exists (
      select 1 from public.bookings b
      where b.car_id = cars.id and b.provider_id = auth.uid()
    )
  );

-- ============================================================
-- 2) BOOKINGS -> CARS LINK
-- ============================================================
alter table public.bookings
  add column if not exists car_id uuid references public.cars (id);

-- ============================================================
-- 3) SERVICES DURATION (Captainz-style "≈ 20 min")
-- ============================================================
alter table public.services
  add column if not exists duration_min int;