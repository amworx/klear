-- Service merchandising: badges + real discounts (T1 booking UX overhaul).
-- Discounts are REAL: customer-facing totals derive from
-- base_price * (1 - discount_percent/100). Admin dashboard manages both
-- columns later; here we only add the columns + demo merch values.

alter table public.services
  add column if not exists discount_percent int,
  add column if not exists badge_key text;

do $$ begin
  alter table public.services
    add constraint services_discount_percent_range
    check (discount_percent is null or discount_percent between 1 and 90);
exception
  when duplicate_object then null;
end $$;

-- Demo merch (matches seed catalog; admin can change freely).
update public.services set badge_key = 'popular', discount_percent = 15
  where name_en = 'Full Care Package';
update public.services set badge_key = 'best_value', discount_percent = 10
  where name_en = 'Weekly bundle';
update public.services set badge_key = 'new'
  where name_en = 'Exterior Wash';
