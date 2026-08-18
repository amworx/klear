# P10 — Admin Dashboard: Klear Control Center

Milestone plan · 2026-08-18 · Status: APPROVED (scope confirmed by user)

## Goal

A dedicated web admin dashboard to operate the entire Klear business: clients,
bookings, services & plans, pricing (full control), providers, and payments.
Gated behind the `admin` role, sharing the existing Supabase project and auth.

## Grounding — what exists today

- **Roles:** `profiles.role` (`customer/provider/admin`), `is_admin()` helper,
  per-owner RLS on profiles/cars/addresses/bookings. **No admin UI exists.**
- **Services:** `services` table (name_ar/en, desc_ar/en, base_price, currency,
  is_active, sort, duration_min), public select only, seeded via SQL.
- **Pricing:** car-size factors (`small 1.0 / medium 1.25 / large 1.5`) and the
  urgent surcharge (`+25%`) are HARDCODED in Dart (`klear_car.dart`,
  booking-draft logic). Not in the DB — admin cannot control them today.
- **Bookings:** full schema (status, time_type, scheduled_at/end, car_id,
  customer_id, provider_id, total_price). No global management path.
- **Payments:** `payments` table (booking_id, method, amount, status) unused.

## Scope IN (user-confirmed)

### Tier 0 — Architecture decision (DEC-0011): separate React admin web app
- New standalone project `klear-admin` (own repo `amworx/klear-admin`), sibling
  of the Flutter app under `code_repo/`. Same Supabase project + auth; admin
  powers come from RLS, **not** service_role (never expose the secret key to a
  client).
- Stack: React + Vite + TypeScript · Tailwind CSS + shadcn/ui (UI Design
  Playbook approved sources) · @supabase/supabase-js · @tanstack/react-query ·
  @tanstack/react-table · recharts · lucide-react · Vercel deploy.
- Auth: email OTP (consistent with DEC-0007), role guard → `/login` or app.

### Tier 1 — DB & RLS foundation (client-side foundation too)
1. Migration `20260818_000008_admin_dashboard.sql`:
   - `app_settings` single-row table (id=1 CHECK): size_small_factor 1.0,
     size_medium_factor 1.25, size_large_factor 1.5, urgent_surcharge_pct 25,
     service_hours_start 08:00, service_hours_end 18:00, currency SYP,
     updated_at. Seed row. RLS: select public (read for pricing), update admin.
   - `profiles.is_active bool not null default true` (block/unblock).
   - Admin RLS policies (via `is_admin()`): bookings select+update all,
     services insert/update/delete, profiles select+update all, cars select
     all, user_addresses select all, payments select+update all.
2. **Client app pricing refactor** (only client changes this milestone):
   - New `AppSettings` domain model + `SettingsRemoteDataSource/Repository`
     (reads `app_settings`), `settingsProvider` (AsyncNotifier) loaded at boot.
   - `KlearCarSize.priceFactor` and the urgent `+25%` multiplier resolve from
     settings, falling back to today's hardcoded defaults when unavailable
     (tests/offline safe).

### Tier 2 — Admin core modules
3. **Auth + layout:** login (email OTP), sidebar (Overview, Bookings, Clients,
   Services & Plans, Pricing & Settings, Providers, Payments), top bar, Arabic
   RTL default + EN.
4. **Overview:** KPI cards (bookings today, pending, total revenue, active
   clients), bookings-per-day chart, recent bookings, pending queue.
5. **Bookings:** full table (search, filter by status/date/service, sort,
   pagination), detail drawer (customer, car, time window, price breakdown,
   payments), status updates (pending→confirmed→in_progress→completed / cancel),
   provider assignment (bookings.provider_id).
6. **Clients:** list/search, detail (profile + cars + addresses + booking
   history + payments), edit profile (name/phone/role), block/unblock
   (is_active).
7. **Services & Plans:** full CRUD — name/desc ar+en, base price, duration,
   active toggle, sort; live price preview per car size using current settings.
8. **Pricing & Settings:** edit size factors, urgent surcharge %, service hours,
   currency (single-row form) — reflected immediately in client estimates.
9. **Providers:** list/create/edit providers, availability toggle, workload
   (assigned bookings count).
10. **Payments:** list, view per booking, mark paid/refunded (cash MVP).

## Scope OUT (deferred)

- Online payment gateway / wallet
- Push/email notifications
- Realtime live-tracking UI
- Audit-trail table for setting changes (record as known gap; can be added later)
- Any other client-facing feature changes (only the pricing refactor touches the app)

## DB changes summary

```
20260818_000008_admin_dashboard.sql
├─ app_settings (single row, pricing + hours + currency) + RLS + seed
├─ profiles.is_active bool default true
└─ admin RLS policies: bookings, services, profiles, cars, user_addresses, payments
```

## l10n (client app)

- Only if the pricing refactor surfaces new user-facing strings (should be none
  — factors are numeric). Regenerate `flutter gen-l10n` if any key changes.

## Tests

- Client: unit tests for settings parsing + factor lookup fallback; existing
  tests stay green (39/39).
- Admin: not a unit-test suite at MVP, but E2E covers every module (below).

## Gates

- `flutter analyze` clean, `flutter test` green after pricing refactor.
- Admin app: `npm run build` + ESLint clean.
- RLS verification: admin (via auth) sees all tables; customer cannot read
  others' rows or mutate services/settings.
- Admin E2E (chrome-devtools, supabase auth session): login → create/edit/disable
  a service → change a pricing factor → verify a fresh client booking estimate
  reflects it → update a booking status → assign provider → block a user → view
  a client detail.
- UI Design Playbook compliance: shadcn, responsive, dark mode, RTL Arabic.

## Memory

- Event EVT-20260818-0049 (plan approved) + completion events.
- Decisions: DEC-0011 (React admin web app), DEC-0012 (pricing config in DB),
  DEC-0013 (full user control incl. block/unblock), DEC-0014 (providers in scope).
- ADR-0002-admin-dashboard.md.
