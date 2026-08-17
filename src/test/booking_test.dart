// Tests for the booking flow state and Riverpod providers.
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:klear/features/bookings/data/bookings_remote_datasource.dart';
import 'package:klear/features/bookings/data/bookings_repository.dart';
import 'package:klear/features/bookings/domain/klear_booking.dart';
import 'package:klear/features/bookings/presentation/booking_providers.dart';
import 'package:klear/features/cars/domain/klear_car.dart';
import 'package:klear/features/services/domain/klear_service.dart';

const _service = KlearService(
  id: 's1',
  nameAr: 'غسيل خارجي',
  nameEn: 'Exterior Wash',
  basePrice: 100,
  currency: 'SYP',
  durationMin: 20,
);

const _smallCar = KlearCar(
  id: 'c1',
  userId: 'u1',
  make: 'Toyota',
  model: 'Yaris',
  plateNumber: '1234A',
  size: KlearCarSize.small,
);

const _largeCar = KlearCar(
  id: 'c2',
  userId: 'u1',
  make: 'Land Rover',
  model: 'Defender',
  plateNumber: '5678B',
  size: KlearCarSize.large,
);

void main() {
  testWidgets('Booking draft starts empty and clears', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(bookingDraftProvider.notifier);

    expect(container.read(bookingDraftProvider).isComplete, false);

    notifier.setAddress('Test Address');
    notifier.setDateTime(DateTime(2026, 1, 1, 10, 0));
    expect(container.read(bookingDraftProvider).address, 'Test Address');
    expect(container.read(bookingDraftProvider).dateTime, DateTime(2026, 1, 1, 10, 0));
    expect(container.read(bookingDraftProvider).isComplete, false);

    notifier.clear();
    expect(container.read(bookingDraftProvider).address, null);
    expect(container.read(bookingDraftProvider).dateTime, null);
  });

  testWidgets('Draft is complete only with service, car, address and time',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(bookingDraftProvider.notifier);

    expect(container.read(bookingDraftProvider).isComplete, false);

    notifier.setService(_service);
    expect(container.read(bookingDraftProvider).isComplete, false);

    notifier.setCar(_smallCar);
    expect(container.read(bookingDraftProvider).isComplete, false);

    notifier.setAddress('Address');
    expect(container.read(bookingDraftProvider).isComplete, false);

    notifier.setDateTime(DateTime(2026, 1, 1, 10, 0));
    expect(container.read(bookingDraftProvider).isComplete, true);
  });

  testWidgets('Estimated total = service base price x car size factor',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(bookingDraftProvider.notifier);

    notifier.setService(_service);
    notifier.setCar(_smallCar);
    // small factor 1.0
    expect(container.read(bookingDraftProvider).estimatedTotal, 100);

    notifier.setCar(_largeCar);
    // large factor 1.5 -> 150
    expect(container.read(bookingDraftProvider).estimatedTotal, 150);
    expect(container.read(bookingDraftProvider).estimatedDurationMin, 20);
  });

  testWidgets('Draft carries the selected car for the confirm screen',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(bookingDraftProvider.notifier);
    notifier.setCar(_largeCar);

    final draft = container.read(bookingDraftProvider);
    expect(draft.car?.id, 'c2');
    expect(draft.car?.plateNumber, '5678B');
    expect(draft.car?.size, KlearCarSize.large);
  });

  testWidgets('Draft defaults to pay-on-arrival and can change method',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(bookingDraftProvider.notifier);
    expect(
      container.read(bookingDraftProvider).paymentMethod,
      BookingPaymentMethod.payOnArrival,
    );

    notifier.setPaymentMethod(BookingPaymentMethod.online);
    expect(
      container.read(bookingDraftProvider).paymentMethod,
      BookingPaymentMethod.online,
    );

    notifier.clear();
    expect(
      container.read(bookingDraftProvider).paymentMethod,
      BookingPaymentMethod.payOnArrival,
    );
  });

  test('statusLabel maps every status in en and ar', () {
    KlearBooking bookingWith(BookingStatus status) => KlearBooking(
          id: 'b1',
          userId: 'u1',
          serviceId: 's1',
          service: _service,
          address: 'A',
          dateTime: DateTime(2026, 1, 1),
          status: status,
          createdAt: DateTime(2026, 1, 1),
        );

    expect(bookingWith(BookingStatus.pending).statusLabel('en'), 'Pending');
    expect(bookingWith(BookingStatus.confirmed).statusLabel('en'), 'Confirmed');
    expect(bookingWith(BookingStatus.inProgress).statusLabel('en'), 'In Progress');
    expect(bookingWith(BookingStatus.completed).statusLabel('en'), 'Completed');
    expect(bookingWith(BookingStatus.cancelled).statusLabel('en'), 'Cancelled');

    expect(bookingWith(BookingStatus.pending).statusLabel('ar'), 'قيد الانتظار');
    expect(bookingWith(BookingStatus.confirmed).statusLabel('ar'), 'مؤكد');
    expect(bookingWith(BookingStatus.inProgress).statusLabel('ar'), 'جاري التنفيذ');
    expect(bookingWith(BookingStatus.completed).statusLabel('ar'), 'مكتمل');
    expect(bookingWith(BookingStatus.cancelled).statusLabel('ar'), 'ملغى');
  });

  test('Draft carries precise coordinates picked on the map', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(bookingDraftProvider.notifier);
    expect(container.read(bookingDraftProvider).lat, isNull);
    expect(container.read(bookingDraftProvider).lng, isNull);

    notifier.setLatLng(33.5138, 36.2765);

    final draft = container.read(bookingDraftProvider);
    expect(draft.lat, 33.5138);
    expect(draft.lng, 36.2765);
    // Coordinates alone don't complete the draft — address is still needed.
    expect(draft.isComplete, isFalse);
  });

  test('cancelBooking delegates to the datasource (status update path)',
      () async {
    final fake = _FakeBookingsDataSource();
    final repo = BookingsRepository(dataSource: fake);

    await repo.cancelBooking('b-123');

    expect(fake.cancelledIds, ['b-123']);
  });
}

class _FakeBookingsDataSource implements BookingsRemoteDataSource {
  final cancelledIds = <String>[];

  @override
  Future<void> cancelBooking(String bookingId) async {
    cancelledIds.add(bookingId);
  }

  @override
  Future<KlearBooking> createBooking({
    required Map<String, dynamic> payload,
    required KlearService service,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<List<KlearBooking>> fetchMyBookings({
    required String userId,
    required Map<String, KlearService> servicesById,
  }) async {
    return const [];
  }
}