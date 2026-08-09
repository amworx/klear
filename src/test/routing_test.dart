// Tests for the bottom navigation shell and basic routing.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:klear/l10n/app_localizations.dart';

import 'helpers.dart';

void main() {
  testWidgets('Unauthenticated users land on the welcome screen',
      (tester) async {
    tester.binding.platformDispatcher.localesTestValue = const [Locale('ar')];
    await tester.pumpWidget(await buildKlearApp());
    await tester.pumpAndSettle();

    // Welcome screen renders.
    expect(find.text('مرحباً بك في كليير'), findsOneWidget);
    expect(find.text('تسجيل الدخول'), findsOneWidget);
  });

  testWidgets('AppLocalizations loads', (tester) async {
    tester.binding.platformDispatcher.localesTestValue = const [Locale('ar')];
    await tester.pumpWidget(await buildKlearApp());
    await tester.pumpAndSettle();
    final loc = AppLocalizations.of(
      tester.element(find.byType(Scaffold).first),
    );
    expect(loc.appTitle, 'كليير');
  });
}
