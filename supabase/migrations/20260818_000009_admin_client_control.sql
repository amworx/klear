-- Klear: P10 — Admin control over client details.
--
-- The admin dashboard client dialog is being upgraded from read-only
-- (profile + cars + addresses lists) to full control organized in tabs.
-- Admins must be able to add/edit/delete a client's cars and saved
-- addresses directly from the web dashboard.
--
-- Permissive policies OR together with the existing owner policies, so
-- client-side behavior is unchanged.

-- ============================================================
-- CARS: admin INSERT/UPDATE/DELETE
-- ============================================================
drop policy if exists "cars_insert_admin" on public.cars;
create policy "cars_insert_admin" on public.cars
  for insert with check (public.is_admin());

drop policy if exists "cars_update_admin" on public.cars;
create policy "cars_update_admin" on public.cars
  for update using (public.is_admin()) with check (public.is_admin());

drop policy if exists "cars_delete_admin" on public.cars;
create policy "cars_delete_admin" on public.cars
  for delete using (public.is_admin());

-- ============================================================
-- USER_ADDRESSES: admin INSERT/UPDATE/DELETE
-- ============================================================
drop policy if exists "user_addresses_insert_admin" on public.user_addresses;
create policy "user_addresses_insert_admin" on public.user_addresses
  for insert with check (public.is_admin());

drop policy if exists "user_addresses_update_admin" on public.user_addresses;
create policy "user_addresses_update_admin" on public.user_addresses
  for update using (public.is_admin()) with check (public.is_admin());

drop policy if exists "user_addresses_delete_admin" on public.user_addresses;
create policy "user_addresses_delete_admin" on public.user_addresses
  for delete using (public.is_admin());