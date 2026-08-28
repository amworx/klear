// Tests for the dynamic car-attribute catalog model, the extra price factor
// computation, and its effect on booking estimates.
import 'package:flutter_test/flutter_test.dart';

import 'package:klear/features/bookings/domain/klear_booking.dart';
import 'package:klear/features/cars/data/car_attributes_repository.dart';
import 'package:klear/features/cars/domain/car_attribute_catalog.dart';
import 'package:klear/features/cars/domain/klear_car.dart';
import 'package:klear/features/services/domain/klear_service.dart';
import 'package:klear/features/settings/domain/app_settings.dart';

CarAttribute _attr(
  String key, {
  String type = 'text',
  bool affectsPrice = false,
  List<Map<String, dynamic>> options = const [],
}) {
  return CarAttribute(
    id: 'attr-$key',
    key: key,
    labelAr: 'أر-$key',
    labelEn: 'en-$key',
    dataType: CarAttrDataType.fromDb(type),
    options: options.map(CarAttributeOption.fromJson).toList(),
    affectsPrice: affectsPrice,
  );
}

void main() {
  group('CarAttribute.fromMap', () {
    test('parses text and select attributes with options + factors', () {
      final select = CarAttribute.fromMap({
        'id': 'a1',
        'key': 'class',
        'label_ar': 'الفئة',
        'label_en': 'Class',
        'data_type': 'select',
        'affects_price': true,
        'options': [
          {'value': 'sedan', 'label_en': 'Sedan', 'factor': 1.0},
          {'value': 'suv', 'label_en': 'SUV', 'factor': 1.5},
        ],
      });
      expect(select.dataType, CarAttrDataType.select);
      expect(select.affectsPrice, true);
      expect(select.options.length, 2);
      expect(select.factorForValue('suv'), 1.5);
      expect(select.factorForValue('missing'), isNull);
      expect(select.labelForValue('suv', 'en'), 'SUV');
    });

    test('text attributes have no price options', () {
      final text = _attr('color');
      expect(text.dataType, CarAttrDataType.text);
      expect(text.factorForValue('red'), isNull);
    });
  });

  group('CarAttributesRepository.computeExtraPriceFactor', () {
    final repo = CarAttributesRepository();
    final catalog = [
      _attr('size', type: 'select', affectsPrice: true, options: [
        {'value': 'small', 'factor': 1.0},
        {'value': 'large', 'factor': 1.5},
      ]),
      _attr('class', type: 'select', affectsPrice: true, options: [
        {'value': 'basic', 'factor': 1.0},
        {'value': 'premium', 'factor': 1.25},
      ]),
      _attr('color', type: 'text'),
    ];

    test('size factor is never double-counted from the catalog', () {
      // size is excluded from extraPriceFactor (it comes from app_settings).
      expect(
          repo.computeExtraPriceFactor({'size': 'large', 'class': 'basic'},
              catalog),
          1.0);
    });

    test('multiplies factors of price-affecting attributes with values', () {
      // premium × 1.25; size excluded; color (not affecting) ignored.
      expect(
          repo.computeExtraPriceFactor({'class': 'premium'}, catalog),
          1.25);
      expect(
          repo.computeExtraPriceFactor({'class': 'premium', 'color': 'red'},
              catalog),
          1.25);
    });

    test('returns 1.0 when no price-affecting value resolves', () {
      expect(repo.computeExtraPriceFactor({}, catalog), 1.0);
      expect(repo.computeExtraPriceFactor({'color': 'red'}, catalog), 1.0);
      expect(
          repo.computeExtraPriceFactor({'class': 'unknown'}, catalog),
          1.0);
    });
  });

  group('pricing integration', () {
    const service = KlearService(
      id: 's1',
      nameAr: 'غسيل',
      nameEn: 'Wash',
      basePrice: 100,
      currency: 'SYP',
      durationMin: 20,
    );

    test('estimatedTotal multiplies size factor and extra price factor', () {
      // small car (size factor 1.0) with an extra factor of 1.5 -> 150.
      const car = KlearCar(
        id: 'c1',
        userId: 'u1',
        make: 'Toyota',
        model: 'Yaris',
        plateNumber: '1',
        size: KlearCarSize.small,
        extraPriceFactor: 1.5,
      );
      final draft = BookingDraft(service: service, car: car);
      expect(draft.estimatedTotal(), 150);
    });

    test('AppSettings.carFactor combines size and extra factors', () {
      const car = KlearCar(
        id: 'c1',
        userId: 'u1',
        make: 'A',
        model: 'B',
        plateNumber: '1',
        size: KlearCarSize.large, // size factor 1.5
        extraPriceFactor: 1.25,
      );
      final s = AppSettings.defaults;
      expect(s.carFactor(car), 1.5 * 1.25);
    });

    test('car without extra attributes prices exactly as before', () {
      // small car, default extraPriceFactor 1.0 -> 100 * 1.0 = 100.
      const car = KlearCar(
        id: 'c1',
        userId: 'u1',
        make: 'A',
        model: 'B',
        plateNumber: '1',
        size: KlearCarSize.small,
      );
      final draft = BookingDraft(service: service, car: car);
      expect(draft.estimatedTotal(), 100);
    });
  });
}
