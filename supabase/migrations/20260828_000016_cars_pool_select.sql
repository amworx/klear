-- Allow captains to read car details for open pool (unassigned, pending)
-- bookings, not just jobs already assigned to them.
--
-- Previously `cars_select_provider` required `b.provider_id = auth.uid()`, so a
-- captain previewing/claiming an unassigned pool job could NOT see the client's
-- car (the `car:cars(...)` embed came back null). The captain needs the
-- make/model/plate before heading out, so we broaden the policy to also cover
-- cars linked to pending bookings that have no provider yet.

drop policy if exists "cars_select_provider" on public.cars;

create policy "cars_select_provider" on public.cars
  for select to authenticated
  using (
    exists (
      select 1
      from public.bookings b
      where b.car_id = cars.id
        and (
          b.provider_id = auth.uid()
          or (b.status = 'pending' and b.provider_id is null)
        )
    )
  );
