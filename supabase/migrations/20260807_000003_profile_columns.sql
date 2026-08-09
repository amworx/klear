-- Klear: add missing columns to `profiles` for the customer / provider location
-- and address fields the app already persists.
--
-- Found during live end-to-end testing: the app's KlearUser model writes
-- `address`, `lat`, `lng` on `profiles`, but the original schema never created
-- them, causing `PGRST204: Could not find the 'address' column`.

alter table public.profiles
  add column if not exists address text,
  add column if not exists lat    double precision,
  add column if not exists lng    double precision;