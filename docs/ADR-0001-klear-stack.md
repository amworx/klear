# ADR-0001 — Klear architecture & stack

- **Status:** Accepted
- **Date:** 2026-08-06
- **Context:** On-demand mobile car wash for Syria (Arabic RTL + English), Android + Web.

## Decisions
1. **Name/Brand:** Klear (كليير), domain `klear.cc`. No car-wash-app competitor named Klear found.
2. **Framework:** Flutter (single codebase for Android + Web).
3. **Backend:** Supabase Free (Postgres, Auth, RLS, Realtime, Storage). No credit card; 500 MB DB; pauses after 7 days idle.
4. **State:** Riverpod recommended (AsyncNotifierProvider + Freezed), or bloc.
5. **Routing:** go_router (declarative).
6. **Localization:** flutter_localizations + `.arb` (ar default/RTL, en fallback).
7. **Architecture:** three-layer UI → Logic → Data, Repository pattern, SSOT, UDF.

## Consequences
- Supabase free-tier pause policy: refresh the project periodically during dev.
- Web deploy available immediately (`build/web`). Android APK builds OK; Play Store submission needs `cmdline-tools` configuration later.