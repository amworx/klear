// Tests for the branded splash page (animated drop loader).
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:klear/app/widgets/klear_drop_loader.dart';
import 'package:klear/app/widgets/klear_splash_page.dart';
import 'package:klear/core/theme/app_theme.dart';
import 'package:klear/l10n/app_localizations.dart';

void main() {
  Widget build() => MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        theme: AppTheme.light(),
        home: const KlearSplashPage(),
      );

  testWidgets('renders animated drop loader only, no wordmark, no spinner',
      (tester) async {
    await tester.pumpWidget(build());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(KlearDropLoader), findsOneWidget);
    // The wordmark is gone — the drop is the only element.
    expect(find.text('Klear'), findsNothing);
    // The boring progress spinner is gone.
    expect(find.byType(CircularProgressIndicator), findsNothing);

    // The loader animates forever — advance with fixed pumps, never
    // pumpAndSettle (an infinite animation would time it out).
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(KlearDropLoader), findsOneWidget);
  });

  testWidgets('loader respects reduced motion (still renders)',
      (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    await tester.pumpWidget(build());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(KlearDropLoader), findsOneWidget);
    expect(find.text('Klear'), findsNothing);
  });
}