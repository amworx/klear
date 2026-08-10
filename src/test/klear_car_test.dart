// Tests for the KlearCar domain model (roundtrip + size pricing factors).
import 'package:flutter_test/flutter_test.dart';

import 'package:klear/features/cars/domain/klear_car.dart';

void main() {
  group('KlearCar.fromMap / toMap', () {
    test('roundtrips a full row from the cars table', () {
      final map = <String, dynamic>{
        'id': 'car-1',
        'user_id': 'user-1',
        'make': 'Toyota',
        'model': 'Corolla',
        'plate_number': '1234A',
        'size': 'medium',
        'created_at': '2026-08-09T10:00:00.000Z',
      };

      final car = KlearCar.fromMap(map);

      expect(car.id, 'car-1');
      expect(car.userId, 'user-1');
      expect(car.make, 'Toyota');
      expect(car.model, 'Corolla');
      expect(car.plateNumber, '1234A');
      expect(car.size, KlearCarSize.medium);
      expect(car.displayName, 'Toyota Corolla');
      expect(car.createdAt, DateTime.parse('2026-08-09T10:00:00.000Z'));

      final payload = car.toPayload();
      expect(payload['make'], 'Toyota');
      expect(payload['user_id'], 'user-1');
      expect(payload['size'], 'medium');
    });

    test('unknown size falls back to medium', () {
      final car = KlearCar.fromMap({'size': 'unknown'});
      expect(car.size, KlearCarSize.medium);
    });
  });

  group('KlearCarSize pricing factors', () {
    test('small = 1.0, medium = 1.25, large = 1.5', () {
      expect(KlearCarSize.small.priceFactor, 1.0);
      expect(KlearCarSize.medium.priceFactor, 1.25);
      expect(KlearCarSize.large.priceFactor, 1.5);
    });

    test('dbValue matches the SQL check constraint', () {
      expect(KlearCarSize.small.dbValue, 'small');
      expect(KlearCarSize.medium.dbValue, 'medium');
      expect(KlearCarSize.large.dbValue, 'large');
    });
  });
}