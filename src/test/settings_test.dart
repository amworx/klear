import 'package:flutter_test/flutter_test.dart';

import 'package:klear/features/bookings/domain/klear_booking.dart';
import 'package:klear/features/cars/domain/klear_car.dart';
import 'package:klear/features/services/domain/klear_service.dart';
import 'package:klear/features/settings/domain/app_settings.dart';

void main() {
  const service = KlearService(
    id: 's1',
    nameAr: 'غسيل',
    nameEn: 'Wash',
    basePrice: 100,
    currency: 'SYP',
  );

  const mediumCar = KlearCar(
    id: 'c2',
    userId: 'u1',
    make: 'Kia',
    model: 'Sorento',
    plateNumber: '456',
    size: KlearCarSize.medium,
  );

  const largeCar = KlearCar(
    id: 'c3',
    userId: 'u1',
    make: 'Toyota',
    model: 'Land Cruiser',
    plateNumber: '789',
    size: KlearCarSize.large,
  );

  group('AppSettings', () {
    test('defaults mirror the original hardcoded pricing', () {
      const s = AppSettings.defaults;
      expect(s.sizeSmallFactor, 1.0);
      expect(s.sizeMediumFactor, 1.25);
      expect(s.sizeLargeFactor, 1.5);
      expect(s.urgentSurchargePct, 25);
      expect(s.urgentSurchargePercent, 0.25);
      expect(s.urgentMultiplier, 1.25);
      expect(s.currency, 'SYP');
    });

    test('fromMap parses DB row values', () {
      final s = AppSettings.fromMap(const {
        'id': 1,
        'size_small_factor': 1.1,
        'size_medium_factor': 1.35,
        'size_large_factor': 1.6,
        'urgent_surcharge_pct': 30,
        'service_hours_start': '09:00:00',
        'service_hours_end': '17:00:00',
        'currency': 'USD',
      });
      expect(s.sizeSmallFactor, 1.1);
      expect(s.sizeMediumFactor, 1.35);
      expect(s.sizeLargeFactor, 1.6);
      expect(s.urgentSurchargePct, 30);
      expect(s.urgentMultiplier, 1.30);
      expect(s.serviceHoursStart, '09:00:00');
      expect(s.serviceHoursEnd, '17:00:00');
      expect(s.currency, 'USD');
    });

    test('fromMap falls back to defaults for missing/partial rows', () {
      final s = AppSettings.fromMap(const {'id': 1});
      expect(s.sizeMediumFactor, AppSettings.defaults.sizeMediumFactor);
      expect(s.urgentSurchargePct, AppSettings.defaults.urgentSurchargePct);
      expect(s.currency, AppSettings.defaults.currency);
    });

    test('priceFactorFor resolves per size from settings', () {
      const s = AppSettings(
        sizeSmallFactor: 1.1,
        sizeMediumFactor: 1.35,
        sizeLargeFactor: 1.7,
        urgentSurchargePct: 25,
        serviceHoursStart: '08:00',
        serviceHoursEnd: '18:00',
        currency: 'SYP',
      );
      expect(s.priceFactorFor(KlearCarSize.small), 1.1);
      expect(s.priceFactorFor(KlearCarSize.medium), 1.35);
      expect(s.priceFactorFor(KlearCarSize.large), 1.7);
    });
  });

  group('BookingDraft pricing with live settings', () {
    test('estimatedTotal uses the settings factor, not the enum default', () {
      const s = AppSettings(
        sizeSmallFactor: 1.1,
        sizeMediumFactor: 1.35,
        sizeLargeFactor: 1.7,
        urgentSurchargePct: 25,
        serviceHoursStart: '08:00',
        serviceHoursEnd: '18:00',
        currency: 'SYP',
      );
      final draft = BookingDraft()
          .copyWith(service: service)
          .copyWith(car: mediumCar);
      // 100 * 1.35 (settings) instead of the old enum 1.25
      expect(draft.estimatedTotal(s), 135);
      // Without settings it falls back to defaults (1.25 -> 125)
      expect(draft.estimatedTotal(), 125);
    });

    test('estimatedTotalWithSurcharge applies the settings urgent rate', () {
      const s = AppSettings(
        sizeSmallFactor: 1.0,
        sizeMediumFactor: 1.25,
        sizeLargeFactor: 1.5,
        urgentSurchargePct: 30,
        serviceHoursStart: '08:00',
        serviceHoursEnd: '18:00',
        currency: 'SYP',
      );
      final draft = BookingDraft()
          .copyWith(service: service)
          .copyWith(car: largeCar)
          .copyWith(
            dateTime: DateTime(2026, 1, 1, 10),
            timeType: TimeWindowType.urgent,
            scheduledEnd: DateTime(2026, 1, 1, 23, 59),
          );
      // 100 * 1.5 = 150 base; urgent +30% -> 195
      expect(draft.estimatedTotalWithSurcharge(s), 195);
      // Defaults would give +25% -> 187.5
      expect(draft.estimatedTotalWithSurcharge(), 187.5);
    });
  });
}