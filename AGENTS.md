# Klear — Project Constraints

Project root: `C:\Users\HP\Documents\code_repo\android\klear`

## Identity
- **Brand:** Klear (كليير) · Domain: klear.cc
- **Product:** On-demand mobile car wash — book a wash at your location and time.
- **Markets:** Syria (primary) + foreign users.

## Non-negotiable product rules
- **Localization:** Arabic (ar) is the **default** UI, RTL, right-to-left layout. English (en) for foreign users. All user-facing strings go through `.arb` files. No hardcoded strings.
- **RTL:** MaterialApp `localizationsDelegates` + `supportedLocales` + `locale` must honor `ar` (RTL) and `en`.
- **Platforms:** Android + Web (via one Flutter codebase).
- **Backend:** Supabase (free tier now) — Postgres + Auth + Row-Level Security + Realtime. No hardcoded secrets; use Supabase env config.
- **Stack:** Flutter, Riverpod (or bloc) state, go_router declarative routing, `flutter_localizations`.

## Architecture
- Three-layer: UI → Logic → Data, unidirectional data flow, single source of truth in Data layer.
- Repository pattern; UI never talks to network.
- Follow `flutter-apply-architecture-best-practices` skill.

## Engineering requirements
- Flutter stable installed at `C:\flutter` (3.44.9, Dart 3.12.2).
- Android SDK present at `C:\Users\HP\AppData\Local\Android\Sdk` (licenses accepted; platforms android-36/36.1; build-tools 34/36). `cmdline-tools/sdkmanager` missing (network 404 on dl.google.com/android/repository) — revisit only for Play Store signing/config.
- Verify with: `flutter analyze` and `flutter test`.
- Keep AAB/APK release-ready; no debug-only code in production.