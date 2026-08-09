# plan — Klear MVP

## Goal
On-demand mobile car wash (mobile & web) — book at your location/time. Syria-first, Arabic RTL + English.

## Stack (locked)
Flutter (Android+Web) · Riverpod · go_router · Supabase Free · flutter_localizations (.arb)

## Phases
### P0 — Foundation (DONE)
- Project scaffolded; Flutter 3.44.9 installed; web build OK; Android SDK buildable.
### P1 — Core app shell & theming
- MaterialApp with ar/en locals + RTL; theme (Klear aqua brand); go_router skeleton; app architecture folders (UI/Logic/Data), Riverpod init.
### P2 — Supabase backend
- Project (Supabase) + schema (services, bookings, users, payments); Auth; RLS policies; Flutter `supabase_flutter` wiring; secure config.
### P3 — Booking flow
- Service catalog (interior/exterior/packages) → location+time picker → confirm → order tracking (status stream).
### P4 — Payments & order tracking
- Payment options (int. gateway) + order status updates (Realtime).
### P5 — Quality & release
- flutter analyze/test (unit+widget per skill); accessibility; Play Store AAB signing (needs sdkmanager config, blocked warning) ; web deploy.

## Open items / blockers
- cmdline-tools missing (env 404) — needed later for Play Store signing config; log a renewal channel to fix.
- Flutter Android build not yet exercised — only web built. Verify `flutter build apk` early in P1.