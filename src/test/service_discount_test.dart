import 'package:flutter_test/flutter_test.dart';
import 'package:klear/features/services/domain/klear_service.dart';

void main() {
  group('KlearService discounts', () {
    test('no discount when column is null', () {
      final s = KlearService.fromMap({
        'id': '1',
        'name_en': 'A',
        'base_price': 300,
        'discount_percent': null,
      });
      expect(s.hasDiscount, isFalse);
      expect(s.finalPrice, 300);
      expect(s.savingsAmount, 0);
    });

    test('real discount reduces the payable price', () {
      final s = KlearService.fromMap({
        'id': '2',
        'name_en': 'B',
        'base_price': 300,
        'discount_percent': 15,
        'badge_key': 'popular',
      });
      expect(s.hasDiscount, isTrue);
      expect(s.finalPrice, closeTo(255, 0.001));
      expect(s.savingsAmount, closeTo(45, 0.001));
      expect(s.badgeKey, 'popular');
    });

    test('zero discount behaves like none', () {
      const s = KlearService(
        id: '3',
        nameAr: '',
        nameEn: 'C',
        basePrice: 100,
        currency: 'SYP',
        discountPercent: 0,
      );
      expect(s.hasDiscount, isFalse);
      expect(s.finalPrice, 100);
    });

    test('round-trip through toMap preserves merch fields', () {
      const original = KlearService(
        id: '4',
        nameAr: 'د',
        nameEn: 'D',
        basePrice: 500,
        currency: 'SYP',
        durationMin: 90,
        discountPercent: 10,
        badgeKey: 'best_value',
      );
      final parsed = KlearService.fromMap(original.toMap());
      expect(parsed.discountPercent, 10);
      expect(parsed.badgeKey, 'best_value');
      expect(parsed.finalPrice, closeTo(450, 0.001));
    });
  });
}
