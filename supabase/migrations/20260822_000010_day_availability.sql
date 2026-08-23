-- Klear T2 — booking calendar availability RPC.
-- RLS lets customers read only their OWN bookings, so free/busy per window
-- must be computed server-side; only aggregate counts are exposed.
-- Capacity = provider teams currently available, managed from klear-admin
-- (profiles.role = 'provider' AND profiles.is_available).
-- Fallback semantics: if NO provider rows exist at all the workspace is
-- considered unconfigured and defaults to 2 teams; if provider rows exist but
-- every one is off-duty, capacity is honestly 0 (fully booked day).
--
-- Windows are fixed business hours in Asia/Damascus local time (Syria is
-- UTC+3 year-round since DST was abolished in Oct 2022):
--   morning   08:00-12:00 · midday 10:00-14:00 · afternoon 14:00-18:00
-- A booking overlaps a window when its [scheduled_at, scheduled_end) interval
-- intersects the window (strict bounds — touching endpoints don't collide).
-- all_day rows (08:00-18:00) naturally occupy every window; urgent rows
-- (start=now, end=23:59) occupy the remaining ones. Legacy zero-length rows
-- block only the instant they point at.

create or replace function public.availability_range(
  from_day date,
  days int default 1
)
returns table (
  day date,
  window_key text,
  booked int,
  capacity int
)
language sql
stable
security definer
set search_path = public
as $$
  with cap as (
    select case
             when (select count(*) from public.profiles
                   where role = 'provider') = 0
               then 2::int   -- workspace not configured yet
             else (select count(*)::int from public.profiles
                   where role = 'provider' and is_available)
           end as n
  ),
  wins(key, from_h, to_h) as (
    values ('morning'::text,   8, 12),
           ('midday'::text,   10, 14),
           ('afternoon'::text, 14, 18)
  ),
  days as (
    select generate_series(
             from_day,
             from_day + (greatest(days, 1) - 1) * interval '1 day',
             interval '1 day'
           )::date as d
  )
  select
    dd.d as day,
    w.key as window_key,
    coalesce((
      select count(*)::int
      from public.bookings b
      where b.status <> 'cancelled'
        and b.scheduled_at
              < ((dd.d + w.to_h * interval '1 hour')
                 at time zone 'Asia/Damascus')
        and coalesce(b.scheduled_end, b.scheduled_at)
              > ((dd.d + w.from_h * interval '1 hour')
                 at time zone 'Asia/Damascus')
    ), 0)::int as booked,
    (select n from cap) as capacity
  from days dd
  cross join wins w
  order by dd.d, w.from_h;
$$;

revoke all on function public.availability_range(date, int) from public;
grant execute on function public.availability_range(date, int)
  to authenticated;
grant execute on function public.availability_range(date, int)
  to service_role;
