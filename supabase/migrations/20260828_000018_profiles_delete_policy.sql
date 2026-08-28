-- Klear: P10 — Admin can delete providers (captains).
--
-- The admin dashboard exposes a delete action on the providers page, but
-- `public.profiles` previously had NO delete RLS policy. As a result an admin
-- DELETE silently matched zero rows (RLS filtered it out), PostgREST returned
-- 204, and the UI showed a misleading success toast — the captain was never
-- actually removed and the FK protection never got a chance to run.
--
-- Fix: add a `profiles_delete_admin` policy so an admin's DELETE actually
-- executes. The intended guardrails now work as designed:
--   * Deleting a captain that is referenced by `bookings.provider_id`
--     (FK `ON DELETE NO ACTION`) raises a foreign-key error -> the dashboard
--     shows the `providerDeleteBlocked` message.
--   * Captains with no bookings are deleted normally -> `providerDeleted`.

drop policy if exists "profiles_delete_admin" on public.profiles;
create policy "profiles_delete_admin" on public.profiles
  for delete using (public.is_admin());
