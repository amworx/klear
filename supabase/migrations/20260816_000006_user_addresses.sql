-- 20260816_000006_user_addresses.sql
-- Address book: per-user saved locations (label, address, lat/lng, default).

create table if not exists public.user_addresses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  label text not null,
  address text not null,
  lat double precision not null,
  lng double precision not null,
  is_default boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists user_addresses_user_id_idx
  on public.user_addresses(user_id);

alter table public.user_addresses enable row level security;

drop policy if exists "user_addresses_select_own" on public.user_addresses;
create policy "user_addresses_select_own" on public.user_addresses
  for select using (auth.uid() = user_id);

drop policy if exists "user_addresses_insert_own" on public.user_addresses;
create policy "user_addresses_insert_own" on public.user_addresses
  for insert with check (auth.uid() = user_id);

drop policy if exists "user_addresses_update_own" on public.user_addresses;
create policy "user_addresses_update_own" on public.user_addresses
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "user_addresses_delete_own" on public.user_addresses;
create policy "user_addresses_delete_own" on public.user_addresses
  for delete using (auth.uid() = user_id);

-- One default per user (mirrors cars_one_default_per_user pattern).
drop index if exists user_addresses_one_default_per_user;
create unique index user_addresses_one_default_per_user
  on public.user_addresses(user_id) where is_default;