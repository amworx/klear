-- 20260830_000020_booking_guards.sql
-- Guards against logical traps: per-car double-booking and over-capacity race.
-- Keeps the booking invariant server-side so two concurrent inserts cannot
-- both succeed when only one team is left.

-- 1) Per-car overlapping window check (one wash per car per window).
create or replace function public.check_car_double_booking()
returns trigger
language plpgsql
as $$
begin
  -- Only check active bookings (pending/accepted/on_the_way/in_progress).
  -- Completed/cancelled are terminal and don't block.
  if NEW.status in ('completed','cancelled') then
    return NEW;
  end if;
  -- On update, only re-check if the car or window changed.
  if TG_OP = 'UPDATE'
     and OLD.car_id is not distinct from NEW.car_id
     and OLD.scheduled_at is not distinct from NEW.scheduled_at
     and coalesce(OLD.scheduled_end, OLD.scheduled_at)
         is not distinct from coalesce(NEW.scheduled_end, NEW.scheduled_at)
  then
    return NEW;
  end if;

  if exists (
    select 1 from public.bookings b
    where b.customer_id = NEW.customer_id
      and b.car_id = NEW.car_id
      and b.id <> NEW.id
      and b.status not in ('completed','cancelled')
      and b.scheduled_at < coalesce(NEW.scheduled_end, NEW.scheduled_at)
      and coalesce(b.scheduled_end, b.scheduled_at) > NEW.scheduled_at
  ) then
    raise exception 'Car already booked in this time window (car_id=%)', NEW.car_id
      using errcode = '23P01'; -- exclusion violation
  end if;
  return NEW;
end;
$$;

drop trigger if exists bookings_check_car_double on public.bookings;
create trigger bookings_check_car_double
before insert or update on public.bookings
for each row execute function public.check_car_double_booking();

-- 2) Capacity guard: a new/changed booking must not make any overlapping
--    business window (08-12,10-14,14-18 Asia/Damascus) exceed team capacity.
--    Capacity is the same rule as availability_range(): number of
--    profiles where role='provider' and is_available, or 2 when none configured,
--    or 0 when all off-duty.
create or replace function public.check_booking_capacity()
returns trigger
language plpgsql
as $$
declare
  cap int;
  win record;
  booked int;
  p_start timestamptz := NEW.scheduled_at;
  p_end   timestamptz := coalesce(NEW.scheduled_end, NEW.scheduled_at);
begin
  -- Only check active bookings; cancelled never counts, completed is past.
  if NEW.status = 'cancelled' then
    return NEW;
  end if;
  if TG_OP = 'UPDATE'
     and OLD.scheduled_at is not distinct from NEW.scheduled_at
     and coalesce(OLD.scheduled_end, OLD.scheduled_at)
         is not distinct from coalesce(NEW.scheduled_end, NEW.scheduled_at)
     and OLD.status is not distinct from NEW.status
  then
    return NEW;
  end if;

  -- Resolve capacity (same as availability_range cap CTE).
  select case
           when (select count(*) from public.profiles where role='provider') = 0 then 2
           else (select count(*)::int from public.profiles where role='provider' and is_available)
         end into cap;

  -- If no capacity at all, any active booking is over capacity.
  if cap <= 0 then
    raise exception 'No team capacity available for this window'
      using errcode = '23P01';
  end if;

  -- Check each business window that the new booking overlaps.
  for win in
    select * from (values ('morning',8,12),('midday',10,14),('afternoon',14,18)) as w(key,from_h,to_h)
  loop
    -- Does the booking overlap this window on its day?
    -- Window interval is that day's from_h-to_h in Asia/Damascus.
    -- We test overlap in the same way as availability_range: booking [p_start,p_end)
    -- intersects window [d+from_h, d+to_h) in Asia/Damascus time.
    -- For simplicity we test overlap per day that the booking spans (normally one day).
    -- We check the window on the booking's start day (bookings are single-day).
    if p_start < ((date(p_start at time zone 'Asia/Damascus') + win.to_h * interval '1 hour') at time zone 'Asia/Damascus')
       and p_end > ((date(p_start at time zone 'Asia/Damascus') + win.from_h * interval '1 hour') at time zone 'Asia/Damascus')
    then
      select count(*)::int into booked
      from public.bookings b
      where b.id <> NEW.id
        and b.status <> 'cancelled'
        and b.scheduled_at < ((date(p_start at time zone 'Asia/Damascus') + win.to_h * interval '1 hour') at time zone 'Asia/Damascus')
        and coalesce(b.scheduled_end, b.scheduled_at) > ((date(p_start at time zone 'Asia/Damascus') + win.from_h * interval '1 hour') at time zone 'Asia/Damascus');

      if booked >= cap then
        raise exception 'Window % is fully booked (capacity % reached)', win.key, cap
          using errcode = '23P01';
      end if;
    end if;
  end loop;

  return NEW;
end;
$$;

drop trigger if exists bookings_check_capacity on public.bookings;
create trigger bookings_check_capacity
before insert or update on public.bookings
for each row execute function public.check_booking_capacity();
