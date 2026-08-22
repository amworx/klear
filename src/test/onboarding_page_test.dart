// Smoke test for the new-user onboarding flow.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:klear/core/theme/app_theme.dart';
import 'package:klear/features/onboarding/presentation/onboarding_page.dart';
import 'package:klear/l10n/app_localizations.dart';

void main() {
  testWidgets('onboarding renders first step + controls (reduced motion)',
      (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          theme: AppTheme.light(),
          home: const OnboardingPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Step 1 copy + controls are present.
    expect(find.text('Book a wash in minutes'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    // Heroes paint without throwing (at least the first step's ripple).
    expect(tester.takeException(), isNull);
  });
}
