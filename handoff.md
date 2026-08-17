# Klear — Handoff for the Next Assistant

> Written 2026-08-10 after milestone P6. Read this first, then `AGENTS.md`
> (global doctrine in `~/.config/opencode/AGENTS.md` when available), then the
> memory files listed below. This file lives at the project ROOT and IS safe
> to commit — it contains **no secrets**. Secrets live only in
> `memory/credentials.md` (gitignored).

---

## 1. What this project is

- **Klear (كليير)** — on-demand **mobile car wash** app: book a wash at your
  location and time. Markets: Syria (primary) + foreign users.
- Flutter (Android + Web, one codebase) + **Supabase** (Postgres + Auth +
  RLS + Realtime) + Riverpod + go_router + `flutter_localizations`
  (ar default RTL, en fallback).
- Product benchmark: **Captainz** (captainzsa.com, Saudi Arabia) — the closest
  market analog. Fold their proven UX (service cards show duration+price,
  4-tab IA, simple booking steps) into our product; our differentiator is
  **size-aware pricing**.

---

## 2. Project layout (root = `C:\Users\HP\Documents\code_repo\android\klear`)

```
AGENTS.md                      # project constraints (product rules, gates)
handoff.md                     # this file
docs/                          # ADR-0001-klear-stack.md etc.
plans/                         # milestone plans (20260809_p6_...md)
tasks/                         # task breakdowns (sparse)
memory/                        # APPEND-ONLY knowledge base (gitignored!)
  events.md  lessons.md  patterns.md  decisions.md  playbooks.md  credentials.md
supabase/migrations/           # SQL schema, applied MANUALLY (see §7)
src/
  lib/
    main.dart
    core/  config/app_config.dart · network/supabase_service.dart
           theme/app_theme.dart · widgets/motion.dart · l10n/locale_controller.dart
    features/
      auth/        welcome · email signin · otp verify · profile setup
      home/        home page + services section
      services/    catalog (domain/data/presentation)
      cars/        My Cars (domain/data/presentation)  ← P6
      bookings/    booking flow (5 steps) + booking data layer  ← P6
      orders/      My Orders tab (still placeholder)
      account/     profile page + auth state
    app/  klear_app.dart (router+theme) · app_router.dart (KlearRoutes) · scaffold_with_navbar.dart
    l10n/ app_ar.arb · app_en.arb (+ generated app_localizations*.dart)
  test/  widget_test · routing_test · booking_test · klear_car_test · helpers.dart
```

---

## 3. Milestones done so far (read `memory/events.md` for details)

| Ms | Content | Status |
|----|---------|--------|
| P1 | Shell + l10n + theme + home | done |
| P2 | Supabase wiring + services catalog | done |
| P3 | go_router 4-tab shell | done |
| P5 | Booking flow (4 steps) + draft state | done (P6 upgraded it) |
| — | Email-OTP auth (no SMS provider), profile setup, Arabic-default locale | done & LIVE-verified |
| — | Soft-UI design system (terracotta theme + motion toolkit) | done |
| — | GitHub upload (private, amworx/klear) | done |
| P6 | **My Cars (size/make/model/plate) + size-aware pricing + real booking persistence + service durations** | done & LIVE-verified |

**Current build state:** `flutter analyze` clean · **12 tests pass** · web
release builds · APK debug built before (VPN needed, see lessons).

---

## 4. Architecture & conventions (KEEP THESE)

- **Three layers** per feature: `domain/` (plain models) → `data/` (datasource +
  repository) → `presentation/` (Riverpod providers + pages). UI never talks to
  network directly; repository is the single source of truth.
- Riverpod 2.x: `FutureProvider` for reads, `StateNotifierProvider` for the
  booking draft and auth; `NotifierProvider` for locale (plain Provider won't
  rebuild on notifyListeners — see lessons).
- **Routing:** go_router builder in `klear_app.dart`; path constants in
  `app_router.dart` (class `KlearRoutes`). **Child navigation constants MUST be
  absolute paths** (`/book/car`) — relative resolves against current location.
  See DEC-0009.
- **l10n:** every user-facing string goes in `app_ar.arb` + `app_en.arb`
  (placeholders need `@key` metadata). After editing run `flutter gen-l10n`.
  Arabic is default & RTL; the in-app toggle (LanguageTile) is on Welcome +
  Account. Never hardcode strings.
- **Theme:** hand-built ColorSchemes in `core/theme/app_theme.dart`
  (terracotta #9A3412 / rust #C2410C / emerald #059669 on cream #FFFBEB).
  Reference `colorScheme.tertiary`/`error` for success/error — never raw
  Colors.green/red. Motion toolkit in `core/widgets/motion.dart`
  (Entrance/StaggerList/AnimatedPress) + `_fadeSlidePage` for all routes.
- **Model↔DB columns must be in lockstep.** `bookings` columns:
  `customer_id` (NOT user_id), `note` (NOT notes), `car_id`, `total_price`,
  `scheduled_at`, `status`. `cars` columns: `user_id`, `make`, `model`,
  `plate_number`, `size`, `created_at`, unique(user_id, plate_number).
- **Product rules (non-negotiable):** ar default RTL, en fallback · Android +
  Web · Supabase backend · three-layer UDF · minimal changes only.

---

## 5. Commands (run from `src/`)

```
C:\flutter\bin\flutter.bat gen-l10n        # after editing .arb
C:\flutter\bin\flutter.bat analyze          # expect "No issues found"
C:\flutter\bin\flutter.bat test             # expect 12/12 green
C:\flutter\bin\flutter.bat build web --release ^
  --dart-define=SUPABASE_URL=https://siqyziuoxdjixkpvksqi.supabase.co ^
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
```

- Flutter stable at `C:\flutter` (3.44.9 / Dart 3.12.2). Android SDK present;
  `cmdline-tools/sdkmanager` missing (only matters for Play signing).
- PHP/python not needed for the app; `python -m http.server 8090` serves
  `src/build/web` for live E2E.

---

## 6. Live E2E workflow (read `memory/playbooks.md` → `web_live_e2e`)

1. Build web with the dart-defines above; serve `build/web` on 127.0.0.1:8090.
2. Drive via chrome-devtools MCP: click the Flutter "Enable accessibility"
   placeholder first (JS `document.querySelector('flt-semantics-placeholder').click()`).
3. **Stale-JS trap after any rebuild:** copy `main.dart.js` to a NEW basename
   ENDING in `.js` (e.g. `main.dart.js.v2.js` — TrustedTypes rejects others) and
   point `flutter_bootstrap.js` `"mainJsPath"` at it, then hard-reload.
4. **Typing into Flutter fields:** use click → Control+A → type_text. The MCP
   `fill`/`fill_form` truncates, and JS `.value=` changes visuals only, not the
   controller. Verify real values via `<input>` elements after focusing.
5. Verify DB writes with `supabase db query` (see §7).
6. A signed-in session (John Doe) persists in the browser at 127.0.0.1:8090.

---

## 7. Supabase & migrations (critical)

- **Credentials:** `memory/credentials.md` ONLY. Never commit/log/echo them.
  App keys go in via `--dart-define` (AppConfig). DB password must be
  URL-encoded (`^`→`%5E`, `%`→`%25`) in any db-url.
- **Direct DB access** (verified working):
  `postgresql://postgres.<ref>:<enc-pass>@aws-0-eu-west-2.pooler.supabase.com:6543/postgres`
  (transaction port 6543; session 5432 TLS-times-out from this host).
- **Applying migrations:** `supabase db push` FAILS here (CLI tracker vs
  manually-applied migrations). Use `supabase db query --db-url <url>`.
  Gotchas: `--file` runs the WHOLE file as ONE prepared statement →
  multi-statement files fail → split on `;`+newline and run one statement per
  temp file in ORDER (a policy referencing a later-added column must come
  after that ALTER). Prefix policies with `drop policy if exists`; wrap enums
  in `do $$ ... exception when duplicate_object`; tables before functions.
- **RLS model:** owner rows gated on `auth.uid() = user_id`/`customer_id`.
  Insert payloads MUST include user_id (RLS `with check`). Provider (wash
  team) reads cars via correlated policy over assigned bookings.
  `services` is publicly readable; `bookings` owner + provider-select.
- Migrations 0001..0004 exist in `supabase/migrations/` and are all applied
  to the live DB.

---

## 8. Known gotchas / lessons (from `memory/lessons.md`, top picks)

- go_router relative paths throw "no routes for location" — use absolute
  child-path constants.
- email OTP is 6–8 digits (never hardcode 6); OTP screen must use
  `pendingEmail` not `user.email` (no session pre-verify).
- Supabase email sends failed once with custom SMTP 500 — if signup emails
  stop arriving, check the SMTP (Resend) config, not app code.
- `supabase db query --db-url <url> --file x` = single prepared statement.
- One-shot animations only for testable loading UI (no infinite shimmer).
- Use `listenManual` when you need `ProviderSubscription` to dispose.
- Network env quirks: Google Maven 404s without VPN (`rasdial eu` full-tunnel
  ProtonVPN); direct dl.google.com repository links 404.

---

## 9. Natural next steps (suggested order)

1. **My Orders tab** — bookings now persist; wire `orders_page.dart` to
   `BookingsRepository.getMyBookings` (join services by id; show status chips
   ar/en; empty state already exists). Add `statusLabel` usage + refresh.
2. **Provider/dashboard side** — wash team needs a view of assigned bookings +
   car identity (make/model/plate/size) — RLS already grants them reads.
3. **Wallet / monthly subscriptions, live captain tracking, ratings** —
   Captainz features; out of scope so far.
4. **README.md** for the repo (setup + dart-defines).
5. Consider GitHub Actions (analyze + test on push) for CI.

---

## 10. Memory discipline (do not skip)

- `memory/*.md` are **append-only**; every meaningful action appends an event
  `EVT-YYYYMMDD-NNNN` (fields: id, timestamp, mode, action, summary, result,
  files, errors, lessons, tags).
- Major workflows get an operation `OP-YYYYMMDD-NNNN`; repeated wins become
  patterns; failures record problem → root cause → fix → lesson.
- If a playbook exists, USE it before inventing a workflow.
- `memory/credentials.md` is gitignored — never commit; never log key strings
  into events/lessons.

## 11. Git

- Remote: `https://github.com/amworx/klear` (PRIVATE). Branch `main`, tracking
  `origin/main`. Commit identity already configured (noreply).
- Latest: `1e9185d` P6 milestone. `memory/` is excluded via `.gitignore` —
  always re-check with `git ls-files | Select-String "credentials|memory"`.
- Only commit/push when the user asks.
---

## P7 UPDATE (2026-08-16) - UX improvements shipped

Latest commit: **P7** (see git log; working tree clean after this session).
- Booking flow now 3 steps: Service -> Details -> **Review & Pay** (payment
  method: pay-on-arrival MVP, online disabled "coming soon").
- Step 2: default-car pre-select + live cost breakdown card; Step 1 footer
  explains base price vs per-car total.
- **My Orders**: cards tappable -> OrderDetailPage (/orders/:id) with status
  chip, car+size, address, time, notes, total; **Cancel** (pending only) ->
  soft status 'cancelled' with confirm dialog + snackbar.
- **Home**: "Upcoming wash" card for the nearest future pending/confirmed
  booking (auto-hides when none remain).
- **My Cars**: star = set as default (cars.is_default + partial unique index
  cars_one_default_per_user); Default chip shown. Migration in
  supabase/migrations/20260816_000005_car_default.sql (already applied live).
- Gates: lutter analyze clean, lutter test 17/17.
- Web E2E verified live on 127.0.0.1:8090 (build main.dart.js.v20260816b.js).
- P8+ backlog unchanged: extras, ratings, real online payment, captain
  tracking, wallet/subscriptions, README, CI.

---

## P8 UPDATE (2026-08-17) - Map picker + per-user address book shipped

Latest commit: **fece180** (P8; pushed to origin/main).
- **Map picker** (flutter_map + OSM tiles + Nominatim) with search + reverse
  geocoding, "Use this location", and "Save to address book" (label: ????/???/????).
- **Address book** (per-user, RLS): /account/addresses, add/delete/set-default,
  selectable mode for booking (GoRoute extra:true). Migration
  supabase/migrations/20260816_000006_user_addresses.sql (applied live).
- **Integrations**: ProfileSetupPage + BookingDetailsPage "Choose on map",
  "Use saved address", current-location now reverse-geocodes; BookingDraft
  carries lat/lng into bookings (columns already existed); Account tile.
- Gates: analyze clean, lutter test 27/27. Web E2E live-verified (4 paths:
  profile map, address book, booking-via-saved-address, booking-via-map-picker;
  lat/lng persisted in DB). Throwaway E2E user cleaned up.
- **Android**: APK builds again via dependency_overrides: path_provider_android:
  2.2.23 (2.3.x jni chain hardcodes compileSdk 35, not installable on this
  network). Location permissions added to manifest. Installed + launched on
  Redmi Note 8 (aabbe8f4): booking step 2 shows Choose-on-map, picker opens.
- Web E2E session key: sb-siqyziuoxdjixkpvksqi-auth-token (see playbooks
  web_live_e2e_auth_session).
- P9+ backlog: extras, ratings, real online payment, captain tracking,
  wallet/subscriptions, README, CI.

## P9 UPDATE (2026-08-17) - Orders tabs, edit booking, flexible time windows shipped

Latest commit: **d1f4468** (P9; pushed to origin/main; includes 0dec094 l10n/migration commit).
- **Orders filter tabs**: /orders has Current / Finished / Cancelled tabs with per-tab
  empty states (orders_filter_test.dart; OrdersFilter + ordersFilteredProvider).
- **Edit booking flow**: order details "????? ?????" prefills the whole draft
  (service/car/address/dateTime/window/lat/lng/notes, editingBookingId) and the
  confirm step PATCHes via BookingsRemoteDataSource.updateBooking (button label
  "??? ?????????", dialog "?? ????? ?????"). Same-row Edit + Cancel buttons on
  details when pending (user-directed).
- **Flexible booking time (user-directed)**: step 2 replaces the exact-time picker
  with day chips (?????/????/???? ????? ??? � date-only picker) + 3 categories:
  all-day "?? ?? ??? 8?�6?", specific 4-hour windows (8�12/10�14/14�18),
  urgent "?? ?? ??? ????? (+25%)" (disabled unless today). Urgent adds +25% on
  the size-adjusted price; live in the footer + breakdown on step 2 and on confirm.
  Persisted as bookings.time_type ('all_day'/'window'/'urgent') + scheduled_end;
  migration supabase/migrations/20260817_000007_flexible_time.sql (applied live,
  legacy rows backfilled scheduled_end=scheduled_at). Labels shared via
  booking_time_labels.dart (BookingTimeLabels.fullLabel) on home/orders/detail.
- **Critical fixes found in live E2E**: (1) Dart enum .name ('allDay') violates the
  DB check ('all_day') -> TimeWindowType.dbValue mapping; (2) estimatedTotal that
  bakes in the surcharge double-counts when EDITING an urgent booking ->
  estimatedTotal (base) vs estimatedTotalWithSurcharge (final, persisted).
- Gates: analyze clean, flutter test 39/39. Web E2E live-verified (all-day 08:00�18:00
  37500, urgent now�23:59 46875 +25%, window 10:00�14:00 37500; edit prefill restores
  urgent without double-count; cancel -> Cancelled tab; pick-another-day date-only
  picker; same-row buttons). APK debug built + installed on Redmi Note 8 (aabbe8f4),
  launched cleanly.
- Web build served at localhost:8090, cache-busted to main.dart.js.v20260817f.js +
  flutter_bootstrap.v20260817f.js (RE-BUST after every flutter build web).
- Note: 3 E2E bookings remain under throwaway user klear-p9-e2e@amworx.dev
  (57cdd905-16b3-4bfb-bba2-4e231a39b729): 2 pending (all-day 8b5e1635, window
  45f45a4f) + 1 cancelled (urgent 4480a261). Clean up with the E2E user later.
- P10+ backlog: extras, ratings, real online payment, captain tracking,
  wallet/subscriptions, README, CI. Also consider surfacing the urgent +25%
  surcharge on the order details price breakdown (currently only on booking steps).
