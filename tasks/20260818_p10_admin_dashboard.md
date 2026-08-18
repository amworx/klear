# P10 — Admin Dashboard: Task Breakdown

Milestone: P10 Admin Dashboard (Klear Control Center) · plan: plans/20260818_p10_admin_dashboard.md
Status: NOT STARTED · Owner: Judy (orchestrated)

## Phase A — Database & client foundation

- [ ] **A1** Write + apply migration `20260818_000008_admin_dashboard.sql`
      (app_settings, profiles.is_active, admin RLS policies). Verify via
      `supabase db query` + service-role REST checks.
- [ ] **A2** RLS verification: admin (auth'd) reads all bookings/services/profiles/
      cars/addresses/payments; customer cannot read others' rows or mutate
      services/settings; anon can read app_settings (public select).
- [ ] **A3** Client app: `AppSettings` model + `SettingsRemoteDataSource` +
      `SettingsRepository` + `settingsProvider` (AsyncNotifier, boot-loaded).
- [ ] **A4** Client app: replace hardcoded `KlearCarSize.priceFactor` and urgent
      `+25%` with settings lookup + fallback defaults. Tests updated; keep 39/39.
- [ ] **A5** Client gates: `flutter analyze` clean, `flutter test` green.

## Phase B — Admin app scaffold & auth

- [ ] **B1** Create `klear-admin` project (React+Vite+TS, Tailwind, shadcn init,
      lucide, react-query, react-table, recharts, supabase-js, react-router).
      Own git repo, AGENTS.md, README. No `npm install` unless user approves.
- [ ] **B2** Supabase client (anon/publishable key + URL), email-OTP login page,
      session handling, role guard (profile.role == 'admin' else denied screen).
- [ ] **B3** App shell: sidebar nav, top bar, RTL (Arabic default) + EN toggle,
      dark mode. Per UI Design Playbook (ui-design.md) — use shadcn components.

## Phase C — Core modules

- [ ] **C1** Overview: KPI cards (bookings today, pending, revenue, active
      clients), bookings-per-day chart, recent bookings, pending queue.
- [ ] **C2** Bookings: table (search/filter/sort/pagination), detail drawer,
      status updates, provider assignment, price-breakdown display.
- [ ] **C3** Clients: list/search, detail (profile+cars+addresses+booking
      history+payments), edit profile, block/unblock, role change.
- [ ] **C4** Services & Plans: CRUD (ar/en fields, base price, duration, active,
      sort), live price preview per car size.
- [ ] **C5** Pricing & Settings: edit size factors, urgent surcharge, service
      hours, currency (single-row form) → reflected in client estimates.
- [ ] **C6** Providers: list/create/edit, availability toggle, workload counts.
- [ ] **C7** Payments: list, view per booking, mark paid/refunded.

## Phase D — Verification & ship

- [ ] **D1** Admin E2E (chrome-devtools + supabase auth session): login →
      service CRUD → pricing change reflected in fresh client booking estimate →
      booking status update → provider assignment → block user → client detail.
- [ ] **D2** Build gates: `npm run build` + ESLint clean (admin); analyze+test
      green (client).
- [ ] **D3** Deploy admin app to Vercel (deploy-to-vercel skill).
- [ ] **D4** Memory: events, lessons, patterns, decisions (DEC-0011..0014);
      update plans status to DONE; commit + push both repos; handoff P10 section.

## Known gaps (recorded, deferred)
- Audit trail for pricing/settings changes (no table yet).
- Bulk actions on bookings/clients (nice-to-have after MVP).
