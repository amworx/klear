import 'package:flutter_test/flutter_test.dart';
import 'package:klear/features/bookings/domain/booking_insights.dart';
import 'package:klear/features/bookings/domain/klear_booking.dart';
import 'package:klear/features/cars/domain/klear_car.dart';
import 'package:klear/features/services/domain/klear_service.dart';

KlearBooking _b({
  required String id,
  required String serviceId,
  BookingStatus status = BookingStatus.completed,
  TimeWindowType type = TimeWindowType.window,
  int hour = 8,
  DateTime? createdAt,
}) {
  final service = KlearService(
    id: serviceId,
    nameAr: 'س',
    nameEn: 's',
    basePrice: 100,
    currency: 'SYP',
  );
  final day = DateTime(2026, 8, 1, hour);
  return KlearBooking(
    id: id,
    userId: 'u1',
    serviceId: serviceId,
    service: service,
    address: 'addr',
    dateTime: day,
    status: status,
    createdAt: createdAt ?? DateTime(2026, 8, 1, 12),
    timeType: type,
  );
}

const full = KlearService(
  id: 'full',
  nameAr: 'ف',
  nameEn: 'f',
  basePrice: 300,
  currency: 'SYP',
);
const weekly = KlearService(
  id: 'weekly',
  nameAr: 'أ',
  nameEn: 'w',
  basePrice: 500,
  currency: 'SYP',
);
const exterior = KlearService(
  id: 'ext',
  nameAr: 'خ',
  nameEn: 'e',
  basePrice: 200,
  currency: 'SYP',
);

void main() {
  group('BookingInsights.compute', () {
    test('empty history yields null everything', () {
      final i = BookingInsights.compute(const [], const [full]);
      expect(i.mostUsedServiceId, isNull);
      expect(i.lastBooking, isNull);
      expect(i.preferredWindow, isNull);
    });

    test('cancelled-only history yields null everything', () {
      final i = BookingInsights.compute(
        [_b(id: '1', serviceId: 'full', status: BookingStatus.cancelled)],
        const [full],
      );
      expect(i.mostUsedServiceId, isNull);
      expect(i.lastBooking, isNull);
    });

    test('most used = argmax over non-cancelled', () {
      final i = BookingInsights.compute(
        [
          _b(id: '1', serviceId: 'weekly'),
          _b(id: '2', serviceId: 'weekly'),
          _b(id: '3', serviceId: 'ext'),
        ],
        const [weekly, exterior, full],
      );
      expect(i.mostUsedServiceId, 'weekly');
    });

    test('tie resolves to earlier catalog position', () {
      final i = BookingInsights.compute(
        [
          _b(id: '1', serviceId: 'ext'),
          _b(id: '2', serviceId: 'weekly'),
        ],
        const [weekly, exterior], // weekly first in catalog
      );
      expect(i.mostUsedServiceId, 'weekly');
    });

    test('last booking = latest createdAt', () {
      final i = BookingInsights.compute(
        [
          _b(id: 'old', serviceId: 'ext', createdAt: DateTime(2026, 7, 1)),
          _b(id: 'new', serviceId: 'full', createdAt: DateTime(2026, 8, 20)),
        ],
        const [exterior, full],
      );
      expect(i.lastBooking!.id, 'new');
    });

    test('preferred window = modal (type,hour), recent wins ties', () {
      final i = BookingInsights.compute(
        [
          _b(id: '1', serviceId: 'ext', hour: 8),
          _b(id: '2', serviceId: 'ext', hour: 12),
          _b(
            id: '3',
            serviceId: 'ext',
            hour: 12,
            createdAt: DateTime(2026, 9, 1),
          ),
        ],
        const [exterior],
      );
      expect(i.preferredWindow, (TimeWindowType.window, 12));
    });
  });

  group('BookingInsights.rebookDraft', () {
    test('prefills service/car/address/window from last booking', () {
      final last = _b(id: '9', serviceId: 'full');
      final car = const KlearCar(
        id: 'c1',
        userId: 'u1',
        make: 'Kia',
        model: 'Sorento',
        plateNumber: '123',
        size: KlearCarSize.medium,
      );
      final draft = BookingInsights.rebookDraft(
        last,
        activeServices: const [full],
        car: car,
      );
      expect(draft, isNotNull);
      expect(draft!.service!.id, 'full');
      expect(draft.car!.id, 'c1');
      expect(draft.address, 'addr');
      expect(draft.timeType, TimeWindowType.window);
      expect(draft.dateTime!.hour, 8);
      expect(draft.isComplete, isTrue);
    });

    test('returns null when the booked service is no longer active', () {
      final last = _b(id: '9', serviceId: 'gone');
      final draft = BookingInsights.rebookDraft(
        last,
        activeServices: const [full],
      );
      expect(draft, isNull);
    });
  });
}
