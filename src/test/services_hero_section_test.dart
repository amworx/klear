import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klear/features/home/presentation/widgets/services_section.dart';
import 'package:klear/features/services/domain/klear_service.dart';
import 'package:klear/l10n/app_localizations.dart';

Widget _host(List<KlearService> services, {String? mostUsedServiceId}) =>
    MaterialApp(
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
            child: ServicesSection(
              servicesAsync: AsyncValue.data(services),
              mostUsedServiceId: mostUsedServiceId,
            ),
          ),
        ),
      ),
    );

void main() {
  final fullCare = const KlearService(
    id: 'full',
    nameAr: 'باقة العناية الكاملة',
    nameEn: 'Full Care Package',
    descAr: 'تنظيف شامل من الداخل والخارج',
    basePrice: 300,
    currency: 'SYP',
    durationMin: 60,
    discountPercent: 15,
    badgeKey: 'popular',
  );
  final exterior = const KlearService(
    id: 'ext',
    nameAr: 'غسيل خارجي',
    nameEn: 'Exterior Wash',
    basePrice: 200,
    currency: 'SYP',
    badgeKey: 'new',
  );
  final interior = const KlearService(
    id: 'int',
    nameAr: 'تنظيف داخلي',
    nameEn: 'Interior Cleaning',
    basePrice: 150,
    currency: 'SYP',
  );

  testWidgets('popular service becomes hero; others join the rail',
      (tester) async {
    await tester.pumpWidget(_host([interior, fullCare, exterior]));
    await tester.pumpAndSettle();

    // Rail header present.
    expect(find.text('كل الخدمات'), findsOneWidget);
    // Hero renders the popular service.
    expect(find.text('باقة العناية الكاملة'), findsOneWidget);
    // Discount burst percentage visible.
    expect(find.text('-15%'), findsOneWidget);
    // Book-now CTA present.
    expect(find.text('احجز الآن'), findsOneWidget);
    // Non-featured services live in the horizontal rail.
    expect(find.text('غسيل خارجي'), findsOneWidget);
    expect(find.text('تنظيف داخلي'), findsOneWidget);
    // Featured must NOT be duplicated inside the rail.
    expect(find.text('باقة العناية الكاملة'), findsOneWidget);
  });

  testWidgets('single-service catalog hides the rail entirely',
      (tester) async {
    await tester.pumpWidget(_host([fullCare]));
    await tester.pumpAndSettle();

    expect(find.text('باقة العناية الكاملة'), findsOneWidget);
    expect(find.text('كل الخدمات'), findsNothing);
  });

  testWidgets('auto most-ordered badge shows only on unbadged rail minis',
      (tester) async {
    // 'تنظيف داخلي' (interior) has no admin badge; exterior has 'new'.
    await tester.pumpWidget(
      _host([interior, fullCare, exterior], mostUsedServiceId: 'int'),
    );
    await tester.pumpAndSettle();

    // Personal mark appears for the unbadged favorite...
    expect(find.text('مفضلتك'), findsOneWidget);
    // ...but never overrides the admin badge.
    expect(find.text('جديد'), findsOneWidget);
  });

  testWidgets('auto badge suppressed when admin badge already set',
      (tester) async {
    await tester.pumpWidget(
      _host([interior, fullCare, exterior], mostUsedServiceId: 'ext'),
    );
    await tester.pumpAndSettle();

    // Exterior is the favorite but carries the 'new' admin badge — the
    // auto mark must not render anywhere.
    expect(find.text('مفضلتك'), findsNothing);
    expect(find.text('جديد'), findsOneWidget);
  });
}
