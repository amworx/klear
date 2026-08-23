# T2 — Booking Calendar & Slot Availability

Parent plan: plans/2026-08-22_booking_ux_overhaul.md
Blocked by: Q1 (window model), Q2 (daily capacity). — RESOLVED:
keep window model; capacity = COUNT(profiles WHERE role='provider' AND
is_available) managed via klear-admin.

## UI approach (user-approved mockup docs/design/slot_picker_mockup.html)
Date strip = package `easy_date_timeline: ^2.0.9` (MIT, ar locale,
itemBuilder for load dots + today/tomorrow tags, custom DisableStrategy for
full days, EasyTheme -> sea-cyan). Isolated behind AvailabilityCalendarStrip
widget so it is swappable (package maintenance risk accepted by user).
Window pills (free/limited/full + capacity bar) remain hand-built.


## Steps
1. SQL migration 20260822_000011_day_availability.sql
   - create or replace function public.day_availability(day date)
     returns table(window_key text, booked int, capacity int)
     language sql stable security definer set search_path = public as $$
       select w.key,
              (select count(*) from bookings b
                where b.status <> 'cancelled'
                  and b.scheduled_at::date = day
                  and b.time_type <> 'urgent'
                  and tstzrange window overlaps b range),
              cap from (values ('morning',...),('midday',...),('afternoon',...)) ...
     $$;  -- exact overlap logic per chosen model (Q1)
   - grant execute to authenticated; revoke from anon.
2. Client datasource: availability_provider.dart
   - FutureProvider.family<DayAvailability, DateTime>(day) calling rpc;
     caches per day; invalidate on booking create/cancel.
3. AppSettings += dailyCapacity (default 1) — read from server settings row if
   exists, else constant fallback.
4. UI step 2 rebuild of schedule section:
   - CalendarStrip: 14 days, dot indicator green/amber/red from availability
     (load only for visible days, lazy per-day fetch on demand).
   - On day select → window capacity pills (e.g. "8–12 · متاح", "10–14 · ممتلئ"
     disabled). Keep All-day card (disabled iff all windows full) + urgent.
   - Selected window writes draft.setTimeWindow with precise start/end as today.
5. Edge cases: past-time windows today disabled; urgent ignores capacity but
   shows warning if today full ("قد يتأخر الفريق").
6. Tests: provider mapping (mock rpc), pill enable/disable logic, draft write.

## Acceptance
- User sees which day/window is free BEFORE committing; full combos unselectable;
  existing bookings still display correctly in orders.
