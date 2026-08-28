-- 20260824_000013_staff_ops.sql
-- Staff/captain operations tables + policies + realtime.
-- Depends on 20260824_000012_on_the_way_status.sql ('on_the_way' committed).
-- 2) Captain live locations -------------------------------------------------
create table if not exists public.captain_locations (
  provider_id       uuid primary key references public.profiles(id) on delete cascade,
  lat               double precision not null,
  lng               double precision not null,
  active_booking_id uuid references public.bookings(id) on delete set null,
  updated_at        timestamptz not null default now()
);

alter table public.captain_locations enable row level security;

-- Captains may only write their own row (and must be providers).
create policy captain_location_write
  on public.captain_locations
  for all
  to authenticated
  using      (provider_id = auth.uid())
  with check (
    provider_id = auth.uid()
    and exists (
      select 1 from public.profiles p
      where p.id = auth.uid() and p.role = 'provider'
    )
  );

-- Read access: the captain themself, admins, OR a customer whose ACTIVE
-- booking (on_the_way / in_progress) is currently assigned to this captain.
create policy captain_location_read
  on public.captain_locations
  for select
  to authenticated
  using (
    provider_id = auth.uid()
    or is_admin()
    or active_booking_id in (
      select b.id from public.bookings b
      where b.customer_id = auth.uid()
        and b.provider_id = captain_locations.provider_id
        and b.status in ('on_the_way', 'in_progress')
    )
  );

-- 3) Provider booking policies ---------------------------------------------
-- Open pool: unassigned pending bookings are visible to every provider so
-- they can claim them (first-tap-wins enforced by conditional UPDATE count).
create policy bookings_select_provider_pool
  on public.bookings
  for select
  to authenticated
  using (is_provider() and provider_id is null and status = 'pending');

-- Transitions: captains may claim unassigned pending jobs (claim sets
-- provider_id + accepted) and progress only their OWN active jobs.
create policy bookings_update_provider
  on public.bookings
  for update
  to authenticated
  using (
    is_provider()
    and (
      (provider_id is null and status = 'pending')
      or provider_id = auth.uid()
    )
  )
  with check (
    is_provider()
    and provider_id = auth.uid()
  );

-- 4) Realtime publications ---------------------------------------------------
alter publication supabase_realtime add table public.captain_locations;
alter publication supabase_realtime add table public.bookings;

