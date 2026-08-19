import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import 'widgets/klear_bottom_nav_bar.dart';

/// Persistent UI shell containing the bottom navigation bar.
///
/// Built on top of [StatefulNavigationShell] (from
/// `StatefulShellRoute.indexedStack`) so each tab keeps its own navigation
/// stack.
class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) {
    // Returning to a tab's initial location when re-tapping the active tab
    // matches Material 3 conventions.
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final inBookingFlow =
        GoRouterState.of(context).uri.path.startsWith('/book');

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: inBookingFlow
          ? null
          : KlearBottomNavBar(
              currentIndex: navigationShell.currentIndex,
              onDestinationSelected: _goBranch,
              destinations: [
                KlearNavDestination(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home,
                  label: l10n.navHome,
                ),
                KlearNavDestination(
                  icon: Icons.local_car_wash_outlined,
                  selectedIcon: Icons.local_car_wash,
                  label: l10n.navServices,
                ),
                KlearNavDestination(
                  icon: Icons.receipt_long_outlined,
                  selectedIcon: Icons.receipt_long,
                  label: l10n.navOrders,
                ),
                KlearNavDestination(
                  icon: Icons.person_outline,
                  selectedIcon: Icons.person,
                  label: l10n.navAccount,
                ),
              ],
            ),
    );
  }
}