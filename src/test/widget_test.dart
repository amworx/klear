// Smoke tests: Klear app boots, Arabic (RTL) is the forced default, and the
// in-app language toggle switches to English and back (persisted choice).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Finder for the popup menu item (generic [CheckedPopupMenuItem]) that
/// contains [inside] — tapping the item itself, not its text label.
Finder languageMenuItem(Finder inside) => find.ancestor(
      of: inside,
      matching: find.byWidgetPredicate((w) => w is CheckedPopupMenuItem),
    );

void main() {
  testWidgets('Boots with Arabic (RTL) even when device is English',
      (WidgetTester tester) async {
    // Simulate an English-only device: the app must STILL show Arabic.
    tester.binding.platformDispatcher.localesTestValue =
        const [Locale('en'), Locale('US')];
    await tester.pumpWidget(await buildKlearApp());
    await tester.pumpAndSettle();

    // Arabic welcome screen (not English).
    expect(find.text('مرحباً بك في كليير'), findsOneWidget);
    expect(find.text('تسجيل الدخول'), findsOneWidget);
    expect(find.text('Welcome to Klear'), findsNothing);
  });

  testWidgets('Language toggle switches to English, then back to Arabic',
      (WidgetTester tester) async {
    tester.binding.platformDispatcher.localesTestValue = const [Locale('ar')];
    await tester.pumpWidget(await buildKlearApp());
    await tester.pumpAndSettle();

    // Welcome screen shows the single-icon language switcher (Arabic label).
    final arabicMenuButton = find.byTooltip('اللغة');
    expect(arabicMenuButton, findsOneWidget);

    // Open the menu and switch to English — no scrolling involved.
    await tester.tap(arabicMenuButton);
    await tester.pumpAndSettle();
    await tester.tap(languageMenuItem(find.text('الإنجليزية')));
    await tester.pumpAndSettle();

    // Welcome screen now renders in English.
    expect(find.text('Welcome to Klear'), findsOneWidget);
    expect(find.byTooltip('Language'), findsOneWidget);

    // Switch back to Arabic via the same menu.
    await tester.tap(find.byTooltip('Language'));
    await tester.pumpAndSettle();
    await tester.tap(languageMenuItem(find.text('Arabic')));
    await tester.pumpAndSettle();
    expect(find.text('مرحباً بك في كليير'), findsOneWidget);
  });
}
