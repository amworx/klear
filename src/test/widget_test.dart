// Smoke tests: Klear app boots, Arabic (RTL) is the forced default, and the
// in-app language toggle switches to English and back (persisted choice).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

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

    // Welcome screen shows the language switcher (Arabic labels).
    expect(find.text('اللغة'), findsOneWidget);

    // Scroll the toggle into view and switch to English.
    await tester.ensureVisible(find.text('الإنجليزية').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('الإنجليزية').last);
    await tester.pumpAndSettle();

    // Welcome screen now renders in English.
    expect(find.text('Welcome to Klear'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);

    // Switch back to Arabic.
    await tester.tap(find.text('Arabic').last);
    await tester.pumpAndSettle();
    expect(find.text('مرحباً بك في كليير'), findsOneWidget);
  });
}