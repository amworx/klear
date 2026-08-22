// Tests for the branded Ripple splash.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:klear/app/widgets/klear_ripple_scene.dart';
import 'package:klear/app/widgets/klear_splash_page.dart';
import 'package:klear/core/theme/app_theme.dart';
import 'package:klear/l10n/app_localizations.dart';

void main() {
  Widget build(Locale locale) => MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        theme: AppTheme.light(),
        home: const KlearSplashPage(),
      );

  testWidgets('renders ripple scene + wordmark, no spinner', (tester) async {
    await tester.pumpWidget(build(const Locale('en')));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(KlearRippleScene), findsOneWidget);
    // Wordmark + tagline are present (localized).
    expect(find.text('Klear'), findsOneWidget);
    // The boring progress spinner is gone.
    expect(find.byType(CircularProgressIndicator), findsNothing);

    // The ripple animates forever — advance with fixed pumps, never
    // pumpAndSettle (an infinite animation would time it out).
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(KlearRippleScene), findsOneWidget);
  });

  testWidgets('respects reduced motion (still renders scene + wordmark)',
      (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    await tester.pumpWidget(build(const Locale('ar')));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(KlearRippleScene), findsOneWidget);
    // Arabic wordmark present under reduced motion.
    expect(find.text('كليير'), findsOneWidget);
  });
}
