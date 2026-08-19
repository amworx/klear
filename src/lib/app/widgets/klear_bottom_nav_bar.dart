import 'package:flutter/material.dart';

/// A single destination for [KlearBottomNavBar].
///
/// Mirrors [NavigationDestination]'s shape: a regular icon, a selected
/// (filled) icon, and a localized label. The bar owns all theming so
/// callers only supply the glyphs + text.
class KlearNavDestination {
  const KlearNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Custom bottom navigation bar in the "google pill" style.
///
/// The selected destination shows a rounded pill (soft shadow, tinted with
/// `primaryContainer`) containing the icon + label; unselected destinations
/// show a bare outline icon. The pill grows/shrinks smoothly via implicit
/// animations.
///
/// Why a custom widget instead of Material's [NavigationBar]:
/// - **RTL-safe by construction.** Each destination is an independent
///   expanded slot; the pill centers itself with [OverflowBox] and [Row]s
///   that respect text direction — no absolute pixel offsets, so the Arabic
///   RTL mirror is automatic.
/// - **Wide labels never wrap.** The selected pill may extend slightly
///   beyond its slot (authentic google_nav_bar look); labels are capped at
///   one line + ellipsis, so they can never stack into "vertical text".
/// - **Brand fit.** Uses the app's "Soft UI Sea" [ColorScheme] tokens
///   (`primaryContainer` / `onPrimaryContainer`) and the soft-shadow
///   language from `app_theme.dart`.
/// - **Reduced-motion aware.** Honors `MediaQuery.disableAnimationsOf` by
///   zeroing animation durations.
///
/// Design (per FlutterGems "google_nav_bar" pattern):
/// - 4 destinations, ~72dp tall, full-width tap targets, 44dp+ touch area.
/// - Selected pill: `primaryContainer` + soft primary shadow + icon & label.
/// - AnimatedSwitcher cross-fades the outline/filled icon.
class KlearBottomNavBar extends StatelessWidget {
  const KlearBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<KlearNavDestination> destinations;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      elevation: 0,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              for (var i = 0; i < destinations.length; i++)
                Expanded(
                  child: _KlearNavItem(
                    destination: destinations[i],
                    selected: i == currentIndex,
                    onTap: () => onDestinationSelected(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KlearNavItem extends StatelessWidget {
  const _KlearNavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final KlearNavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final growDuration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 260);
    final iconDuration =
        reduceMotion ? Duration.zero : const Duration(milliseconds: 150);

    final iconColor = selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;

    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: destination.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        // OverflowBox (instead of Align) lets the selected pill grow beyond
        // its slot when the label is wide (authentic google_nav_bar look:
        // the pill extends into the neighbors, label stays centered).
        // Centered → RTL-safe; capped so absurd labels can't take over the
        // bar. The label itself is single-line + ellipsized as a hard
        // guarantee that it never wraps (wrapped labels look like "vertical
        // text" next to the icon).
        child: OverflowBox(
          alignment: Alignment.center,
          minWidth: 0,
          minHeight: 0,
          maxWidth: 190,
          maxHeight: double.infinity,
          child: AnimatedContainer(
            duration: growDuration,
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: selected ? 16 : 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: selected ? scheme.primaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(
                    alpha: selected ? 0.22 : 0.0,
                  ),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: AnimatedSize(
              duration: growDuration,
              curve: Curves.easeOutCubic,
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: iconDuration,
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: Icon(
                      selected ? destination.selectedIcon : destination.icon,
                      key: ValueKey<bool>(selected),
                      size: 24,
                      color: iconColor,
                    ),
                  ),
                  if (selected) ...[
                    const SizedBox(width: 6),
                    // Flexible makes the text a flex child so it is bounded
                    // by the pill width (non-flex children get unbounded
                    // main-axis constraints and would never ellipsize).
                    Flexible(
                      child: Text(
                        destination.label,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelLarge?.copyWith(
                          color: scheme.onPrimaryContainer,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}