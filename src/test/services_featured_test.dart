import 'package:flutter_test/flutter_test.dart';
import 'package:klear/features/services/domain/klear_service.dart';

void main() {
  final fullCare = const KlearService(
    id: 'full',
    nameAr: 'باقة العناية الكاملة',
    nameEn: 'Full Care Package',
    basePrice: 300,
    currency: 'SYP',
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

  group('KlearService.featuredOf', () {
    test('prefers the popular-badged service regardless of order', () {
      final featured = KlearService.featuredOf([interior, fullCare, exterior]);
      expect(featured.id, 'full');
    });

    test('falls back to the first service when no popular badge', () {
      final featured = KlearService.featuredOf([interior, exterior]);
      expect(featured.id, 'int');
    });

    test('single-item catalog yields that item', () {
      expect(KlearService.featuredOf([exterior]).id, 'ext');
    });
  });
}
