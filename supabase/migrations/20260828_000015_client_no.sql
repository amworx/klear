-- 20260828_000015_client_no.sql
-- Add a global, human-friendly sequential client number (e.g. CL-1001) to
-- profiles so same-named clients can be told apart across all three apps
-- (customer / staff / admin). Rendered from a dedicated sequence.
--
-- Design notes:
--  * A `before insert` trigger assigns client_no on ANY new profile insert:
--      - customer app signup (profiles.upsert -> insert when new)
--      - admin-create-user edge function (creates auth user + profile row)
--      - any future profile-creation path
--  * The trigger only fires on INSERT of a NEW row and leaves an explicitly
--    supplied client_no untouched, so it never overwrites existing values on
--    later profile updates (upserts become updates and skip the trigger).
--  * RLS: staff read client_no through the existing profiles_select_provider
--    policy (captains may read the full profile of an assigned customer);
--    admin reads it via the service-role key (RLS bypass). No new policy
--    needed for the existing access paths.

-- ============================================================
-- 1) Sequence for the numeric part of the client number
-- ============================================================
create sequence if not exists public.client_no_seq
  as integer
  start with 1
  increment by 1
  no cycle;

-- ============================================================
-- 2) Column (nullable until backfilled)
-- ============================================================
alter table public.profiles
  add column if not exists client_no text;

-- ============================================================
-- 3) Backfill existing rows with sequential numbers
--    Deterministic order so re-runs are not possible (only runs when null).
-- ============================================================
do $$
declare
  r record;
begin
  for r in
    select id
    from public.profiles
    where client_no is null
    order by created_at, id
  loop
    update public.profiles
       set client_no = 'CL-' || lpad(nextval('public.client_no_seq')::text, 4, '0')
     where id = r.id;
  end loop;
end $$;

-- ============================================================
-- 4) Trigger function + trigger for future inserts
-- ============================================================
create or replace function public.assign_client_no() returns trigger
  language plpgsql as $$
begin
  if new.client_no is null then
    new.client_no := 'CL-' || lpad(nextval('public.client_no_seq')::text, 4, '0');
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_assign_client_no on public.profiles;
create trigger profiles_assign_client_no
  before insert on public.profiles
  for each row execute function public.assign_client_no();
