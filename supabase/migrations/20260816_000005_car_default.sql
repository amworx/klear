-- P7: one default car per user (pre-selected in the booking flow).

alter table public.cars
  add column if not exists is_default boolean not null default false;

-- Enforce at most one default car per user (partial unique index).
create unique index if not exists cars_one_default_per_user
  on public.cars (user_id)
  where is_default;