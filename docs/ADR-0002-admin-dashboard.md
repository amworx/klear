# ADR-0002 — Admin dashboard: separate React web app (Klear Control Center)

- **Status:** Accepted
- **Date:** 2026-08-18
- **Context:** Klear needs an admin dashboard to operate clients, bookings,
  services/plans, pricing, providers, and payments. The Flutter app has no
  admin UI; pricing factors are hardcoded in Dart; RLS has no admin policies.

## Decision
1. **Build the admin dashboard as a separate React web app** (`klear-admin`,
   repo `amworx/klear-admin`) rather than admin routes inside the Flutter app.
   - Stack: React + Vite + TypeScript, Tailwind + shadcn/ui, @supabase/supabase-js,
     @tanstack/react-query + @tanstack/react-table, recharts, lucide-react,
     Vercel deploy.
   - Rationale: industry-standard for dense CRUD dashboards, fast iteration,
     shadcn/ui is an approved source in the UI Design Playbook, matches the
     proven meraki-dashboard pattern, deploys independently, and does not bloat
     the mobile APK. The Flutter app stays customer-facing only.
2. **Share the existing Supabase project and auth** (email OTP, `admin` role).
   Admin powers come from RLS policies keyed on `is_admin()` — **never** expose
   the service_role key to the admin web client.
3. **Move pricing configuration into the DB** (`app_settings` single-row table:
   car-size factors, urgent surcharge %, service hours, currency). The Flutter
   app reads these via a settings repository with hardcoded fallbacks, so admin
   price changes take effect in client estimates without an app release.

## Consequences
- Two codebases to maintain; the client app is touched only by the pricing
  refactor (settings model + provider + factor lookup).
- A migration batch adds `app_settings`, `profiles.is_active`, and admin RLS
  policies on bookings/services/profiles/cars/user_addresses/payments.
- Admin web E2E and RLS verification are required gates for the milestone.
