// Tests for the custom KlearBottomNavBar (google-pill style).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:klear/app/widgets/klear_bottom_nav_bar.dart';
import 'package:klear/core/theme/app_theme.dart';

Widget _wrap({
  required int currentIndex,
  required ValueChanged<int> onDestinationSelected,
}) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(
      body: KlearBottomNavBar(
        currentIndex: currentIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: const [
          KlearNavDestination(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home,
            label: 'Home',
          ),
          KlearNavDestination(
            icon: Icons.local_car_wash_outlined,
            selectedIcon: Icons.local_car_wash,
            label: 'Services',
          ),
          KlearNavDestination(
            icon: Icons.receipt_long_outlined,
            selectedIcon: Icons.receipt_long,
            label: 'Orders',
          ),
          KlearNavDestination(
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: 'Account',
          ),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets('renders 4 destinations and shows the selected label',
      (tester) async {
    await tester.pumpWidget(_wrap(currentIndex: 0, onDestinationSelected: (_) {}));
    await tester.pumpAndSettle();

    // All four icons are present.
    expect(find.byIcon(Icons.home_outlined), findsNothing);
    expect(find.byIcon(Icons.home), findsOneWidget); // selected filled icon
    expect(find.byIcon(Icons.local_car_wash_outlined), findsOneWidget);
    expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);

    // Only the selected destination exposes its label visually.
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Services'), findsNothing);
    expect(find.text('Orders'), findsNothing);
    expect(find.text('Account'), findsNothing);
  });

  testWidgets('reports taps with the destination index', (tester) async {
    final tapped = <int>[];
    await tester.pumpWidget(_wrap(
      currentIndex: 0,
      onDestinationSelected: tapped.add,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.receipt_long_outlined));
    expect(tapped, [2]);

    await tester.tap(find.byIcon(Icons.person_outline));
    expect(tapped, [2, 3]);
  });

  testWidgets('highlights the newly selected destination after rebuild',
      (tester) async {
    await tester.pumpWidget(_wrap(currentIndex: 0, onDestinationSelected: (_) {}));
    await tester.pumpAndSettle();

    await tester.pumpWidget(_wrap(currentIndex: 2, onDestinationSelected: (_) {}));
    await tester.pumpAndSettle();

    expect(find.text('Orders'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
    expect(find.byIcon(Icons.receipt_long), findsOneWidget); // filled icon
  });

  testWidgets('labels are exposed to semantics on every destination',
      (tester) async {
    await tester.pumpWidget(_wrap(currentIndex: 0, onDestinationSelected: (_) {}));
    await tester.pumpAndSettle();

    // Every destination is announced to screen readers with its label
    // (the selected one's label node is merged into the item Semantics).
    expect(find.bySemanticsLabel('Home'), findsOneWidget);
    expect(find.bySemanticsLabel('Services'), findsOneWidget);
    expect(find.bySemanticsLabel('Orders'), findsOneWidget);
    expect(find.bySemanticsLabel('Account'), findsOneWidget);
  });

  testWidgets('works in RTL (Arabic) text direction', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: MediaQuery(
          data: const MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: KlearBottomNavBar(
                currentIndex: 0,
                onDestinationSelected: (_) {},
                destinations: const [
                  KlearNavDestination(
                    icon: Icons.home_outlined,
                    selectedIcon: Icons.home,
                    label: 'الرئيسية',
                  ),
                  KlearNavDestination(
                    icon: Icons.local_car_wash_outlined,
                    selectedIcon: Icons.local_car_wash,
                    label: 'الخدمات',
                  ),
                  KlearNavDestination(
                    icon: Icons.receipt_long_outlined,
                    selectedIcon: Icons.receipt_long,
                    label: 'طلباتي',
                  ),
                  KlearNavDestination(
                    icon: Icons.person_outline,
                    selectedIcon: Icons.person,
                    label: 'حسابي',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Selected label visible in RTL too; tapping the last slot works.
    expect(find.text('الرئيسية'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.person_outline));
    expect(tester.takeException(), isNull);
  });
}