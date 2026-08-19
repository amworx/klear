# ADR-0003 — Custom bottom navigation bar (native "google pill" style)

- **Status:** Accepted
- **Date:** 2026-08-19
- **Context:** The main app's bottom navigation used Material 3's stock
  `NavigationBar`. We evaluated the FlutterGems bottom-navigation-bar catalog
  (~70 packages: convex, curved, google_nav_bar, bottom_navy_bar,
  persistent_bottom_nav_bar_v2, etc.) to give the shell a more distinctive,
  brand-fitting look. Most popular packages carry "Poor" maintenance status;
  the RTL-safe ones still introduce a dependency with their own theming and
  animation assumptions.

## Decision
1. **Build a small custom widget (`KlearBottomNavBar`) instead of adding a
   package.** Style follows the popular "google pill" pattern (rounded pill
   behind the selected icon + label; outline icons otherwise).
   - `src/lib/app/widgets/klear_bottom_nav_bar.dart`; destinations stay
     `KlearNavDestination(icon, selectedIcon, label)`.
   - Uses the app's `ColorScheme` tokens (`primaryContainer` /
     `onPrimaryContainer`) and the Soft UI Sea soft-shadow language — no
     foreign palette.
   - **RTL-safe by construction:** each destination is an independent
     `Expanded` slot with an `Align`-centered pill; no absolute pixel offsets,
     so the Arabic RTL mirror is automatic.
   - Honors `MediaQuery.disableAnimationsOf` (zero-duration animations).
   - Semantics: each item is a labeled button with `selected` state for
     TalkBack; visual labels are hidden only for unselected items, never from
     the semantics tree.
2. **Keep the existing navigation architecture.** `StatefulShellRoute
   .indexedStack` (state preservation) and the `_goBranch` re-tap-to-root
   behavior are unchanged; only the visual bar is swapped in
   `scaffold_with_navbar.dart`.
3. **No new dependency.** The FlutterGems page's own best practices
   (state preservation, icon + label, hide-on-scroll optional) are already
   met or deliberately not needed (bar stays persistent; booking flow already
   hides it via route path).

## Consequences
- ~160 lines of first-party widget code to maintain (trivial).
- Zero package maintenance/version risk; no foreign theming to fight.
- Verified: `flutter analyze` clean, 5 new widget tests (rendering, taps,
  selection, semantics, RTL) + full suite green (50 tests), and on-device
  E2E on the Galaxy A34 (USB + wireless adb): session injected, Home/Services
  tabs render, pill selection moves, RTL order correct (Home rightmost).
- Screenshots: `docs/bottomnav_home.png`, `docs/bottomnav_services.png`.