-- Flexible booking time windows.
-- Adds a time-type flag and an end timestamp so a booking can express:
--   all_day  -> "Anytime 8am-6pm"   (scheduled_at = 08:00, scheduled_end = 18:00)
--   window   -> "8am-12pm / 10am-2pm / 2pm-6pm" (scheduled_at = start, scheduled_end = end)
--   urgent   -> "Anytime today (+25%)" (scheduled_at = now, scheduled_end = end of day)
-- Legacy rows (point-in-time bookings) keep time_type='window' with scheduled_end = scheduled_at.

alter table public.bookings
  add column if not exists time_type text not null default 'window'
    check (time_type in ('all_day', 'window', 'urgent'));

alter table public.bookings
  add column if not exists scheduled_end timestamptz;

-- Backfill: legacy point-in-time bookings behave as zero-length windows.
update public.bookings
set scheduled_end = scheduled_at
where scheduled_end is null;