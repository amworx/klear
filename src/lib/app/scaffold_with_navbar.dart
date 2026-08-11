import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';

/// Persistent UI shell containing the bottom NavigationBar.
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
          : NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _goBranch,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.local_car_wash_outlined),
            selectedIcon: const Icon(Icons.local_car_wash),
            label: l10n.navServices,
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: const Icon(Icons.receipt_long),
            label: l10n.navOrders,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: l10n.navAccount,
          ),
        ],
      ),
    );
  }
}
