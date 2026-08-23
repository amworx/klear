import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klear/features/home/presentation/widgets/services_section.dart';
import 'package:klear/features/services/domain/klear_service.dart';
import 'package:klear/l10n/app_localizations.dart';

Widget _host(List<KlearService> services) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ar'),
      home: Scaffold(
        body: SingleChildScrollView(
          child: ProviderScope(
            child: ServicesSection(servicesAsync: AsyncValue.data(services)),
          ),
        ),
      ),
    );

void main() {
  testWidgets('worst-case mini card (badge+discount+duration) does not overflow',
      (tester) async {
    final fullCare = const KlearService(
      id: 'full',
      nameAr: 'باقة العناية الكاملة',
      nameEn: 'Full Care Package',
      basePrice: 300,
      currency: 'SYP',
      discountPercent: 15,
      badgeKey: 'popular',
    );
    // Mirrors the Weekly bundle row from production: badge + discount +
    // duration -> the tallest possible rail card stack.
    final weekly = const KlearService(
      id: 'wk',
      nameAr: 'باقة اسبوعية',
      nameEn: 'Weekly Bundle',
      basePrice: 500,
      currency: 'SYP',
      durationMin: 15,
      discountPercent: 10,
      badgeKey: 'best_value',
    );
    await tester.pumpWidget(_host([fullCare, weekly]));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
