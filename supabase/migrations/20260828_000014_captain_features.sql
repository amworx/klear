-- 20260828_000014_captain_features.sql
-- Captain-app feature backend: fixes blank client info, adds per-job timing
-- columns, and adds booking chat (client <-> captain).
-- Depends on 20260824_000013_staff_ops.sql (captain_locations, is_provider).

-- ============================================================
-- 1) Provider read access to customer profiles (fixes blank client/phone)
--    A captain may read the profile (name/phone) of any customer who has a
--    booking assigned to them, so job details show who they're serving.
-- ============================================================
create policy profiles_select_provider
  on public.profiles
  for select
  to authenticated
  using (
    is_provider()
    and id in (
      select b.customer_id from public.bookings b
      where b.provider_id = auth.uid()
    )
  );

-- ============================================================
-- 2) Per-job timing columns (accepted / arrived / started / completed)
--    Stamped by the captain app on each status transition so history can show
--    when a job was started and how long it took.
-- ============================================================
alter table public.bookings add column if not exists accepted_at  timestamptz;
alter table public.bookings add column if not exists arrived_at   timestamptz;
alter table public.bookings add column if not exists started_at   timestamptz;
alter table public.bookings add column if not exists completed_at timestamptz;

-- ============================================================
-- 3) Booking chat (client <-> captain)
-- ============================================================
create table if not exists public.booking_messages (
  id          uuid primary key default gen_random_uuid(),
  booking_id  uuid not null references public.bookings (id) on delete cascade,
  sender_id   uuid not null references public.profiles (id) on delete cascade,
  body        text not null check (char_length(body) between 1 and 2000),
  created_at  timestamptz not null default now()
);

create index if not exists booking_messages_booking_idx
  on public.booking_messages (booking_id, created_at);

alter table public.booking_messages enable row level security;

-- Read: the booking's customer, the assigned provider, or an admin.
create policy booking_messages_select
  on public.booking_messages
  for select
  to authenticated
  using (
    is_admin()
    or sender_id = auth.uid()
    or booking_id in (
      select b.id from public.bookings b
      where b.customer_id = auth.uid()
         or b.provider_id = auth.uid()
    )
  );

-- Write: only the booking's customer or assigned provider may post; the sender
-- must be the current user, so messages can't be forged on another's behalf.
create policy booking_messages_insert
  on public.booking_messages
  for insert
  to authenticated
  with check (
    sender_id = auth.uid()
    and booking_id in (
      select b.id from public.bookings b
      where b.customer_id = auth.uid()
         or b.provider_id = auth.uid()
    )
  );

-- ============================================================
-- 4) Realtime: push chat messages + booking timing live.
-- ============================================================
alter publication supabase_realtime add table public.booking_messages;
