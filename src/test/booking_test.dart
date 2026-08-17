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

  test('Urgent windows add +25% to the estimated total', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(bookingDraftProvider.notifier);
    notifier.setService(_service);
    notifier.setCar(_largeCar);
    // large factor 1.5 -> 150 base.
    expect(container.read(bookingDraftProvider).estimatedTotal, 150);

    notifier.setTimeWindow(
      dateTime: DateTime(2026, 1, 1, 10, 0),
      timeType: TimeWindowType.urgent,
      scheduledEnd: DateTime(2026, 1, 1, 23, 59),
    );
    // Base stays size-adjusted (150); the surcharge is applied on demand.
    expect(container.read(bookingDraftProvider).estimatedTotal, 150);
    // 150 * 1.25 = 187.5
    expect(
      container.read(bookingDraftProvider).estimatedTotalWithSurcharge,
      187.5,
    );
    expect(container.read(bookingDraftProvider).isUrgent, isTrue);
  });

  test('setTimeWindow stores start, end and flexibility type', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(bookingDraftProvider.notifier);
    notifier.setTimeWindow(
      dateTime: DateTime(2026, 1, 1, 8, 0),
      timeType: TimeWindowType.window,
      scheduledEnd: DateTime(2026, 1, 1, 12, 0),
    );

    final draft = container.read(bookingDraftProvider);
    expect(draft.dateTime, DateTime(2026, 1, 1, 8, 0));
    expect(draft.scheduledEnd, DateTime(2026, 1, 1, 12, 0));
    expect(draft.timeType, TimeWindowType.window);
    expect(draft.isUrgent, isFalse);
  });

  test('All-day windows are not urgent and keep their window end', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(bookingDraftProvider.notifier);
    notifier.setService(_service);
    notifier.setCar(_smallCar);
    notifier.setTimeWindow(
      dateTime: DateTime(2026, 1, 1, 8, 0),
      timeType: TimeWindowType.allDay,
      scheduledEnd: DateTime(2026, 1, 1, 18, 0),
    );

    final draft = container.read(bookingDraftProvider);
    expect(draft.timeType, TimeWindowType.allDay);
    expect(draft.isUrgent, isFalse);
    expect(draft.scheduledEnd, DateTime(2026, 1, 1, 18, 0));
    expect(draft.estimatedTotal, 100);
    expect(draft.estimatedTotalWithSurcharge, 100);
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

  test('updateBooking delegates to the datasource (edit path)', () async {
    final fake = _FakeBookingsDataSource();
    final repo = BookingsRepository(dataSource: fake);

    final payload = <String, dynamic>{
      'service_id': 's1',
      'car_id': 'c1',
      'address': 'New Address',
      'scheduled_at': DateTime(2026, 2, 1, 12, 0).toIso8601String(),
    };
    await repo.updateBooking(
      bookingId: 'b-123',
      payload: payload,
      service: _service,
    );

    expect(fake.updatedIds, ['b-123']);
    expect(fake.lastUpdatePayload?['address'], 'New Address');
  });

  test('startEdit prefills the draft and marks it as an edit', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(bookingDraftProvider.notifier);
    notifier.startEdit(
      bookingId: 'b-1',
      service: _service,
      car: _largeCar,
      address: 'Damascus, Mezzeh',
      dateTime: DateTime(2026, 3, 1, 11, 0),
      timeType: TimeWindowType.window,
      scheduledEnd: DateTime(2026, 3, 1, 15, 0),
      lat: 33.5,
      lng: 36.3,
      notes: 'Please use the main gate',
    );

    final draft = container.read(bookingDraftProvider);
    expect(draft.isEditing, isTrue);
    expect(draft.editingBookingId, 'b-1');
    expect(draft.service?.id, 's1');
    expect(draft.car?.id, 'c2');
    expect(draft.address, 'Damascus, Mezzeh');
    expect(draft.lat, 33.5);
    expect(draft.lng, 36.3);
    expect(draft.dateTime, DateTime(2026, 3, 1, 11, 0));
    expect(draft.scheduledEnd, DateTime(2026, 3, 1, 15, 0));
    expect(draft.timeType, TimeWindowType.window);
    expect(draft.notes, 'Please use the main gate');
    expect(draft.isComplete, isTrue);
  });

  test('startNew clears any leftover edit session', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(bookingDraftProvider.notifier);
    notifier.startEdit(
      bookingId: 'b-1',
      service: _service,
      car: _smallCar,
      address: 'A',
      dateTime: DateTime(2026, 3, 1, 11, 0),
    );
    expect(container.read(bookingDraftProvider).isEditing, isTrue);

    notifier.startNew();
    final draft = container.read(bookingDraftProvider);
    expect(draft.isEditing, isFalse);
    expect(draft.editingBookingId, isNull);
    expect(draft.isComplete, isFalse);
  });

  test('Booking draft parses lat/lng coordinates from the row', () {
    final booking = KlearBooking.fromMap(
      {
        'id': 'b1',
        'customer_id': 'u1',
        'service_id': 's1',
        'address': 'Damascus',
        'scheduled_at': '2026-01-01T10:00:00.000Z',
        'status': 'pending',
        'created_at': '2026-01-01T09:00:00.000Z',
        'lat': 33.5138,
        'lng': 36.2765,
      },
      _service,
    );

    expect(booking.lat, 33.5138);
    expect(booking.lng, 36.2765);
  });

  test('Booking parses time_type and scheduled_end from the row', () {
    final allDay = KlearBooking.fromMap(
      {
        'id': 'b1',
        'customer_id': 'u1',
        'service_id': 's1',
        'address': 'Damascus',
        'scheduled_at': '2026-01-01T08:00:00.000Z',
        'scheduled_end': '2026-01-01T18:00:00.000Z',
        'time_type': 'all_day',
        'status': 'pending',
        'created_at': '2026-01-01T09:00:00.000Z',
      },
      _service,
    );
    expect(allDay.timeType, TimeWindowType.allDay);
    expect(allDay.scheduledEnd, DateTime.parse('2026-01-01T18:00:00.000Z'));
    expect(allDay.isUrgent, isFalse);
    expect(allDay.windowEnd, DateTime.parse('2026-01-01T18:00:00.000Z'));

    final urgent = KlearBooking.fromMap(
      {
        'id': 'b2',
        'customer_id': 'u1',
        'service_id': 's1',
        'address': 'Damascus',
        'scheduled_at': '2026-01-01T10:00:00.000Z',
        'scheduled_end': '2026-01-01T23:59:00.000Z',
        'time_type': 'urgent',
        'status': 'pending',
        'created_at': '2026-01-01T09:00:00.000Z',
      },
      _service,
    );
    expect(urgent.timeType, TimeWindowType.urgent);
    expect(urgent.isUrgent, isTrue);

    // Legacy rows without time_type default to a point-in-time window.
    final legacy = KlearBooking.fromMap(
      {
        'id': 'b3',
        'customer_id': 'u1',
        'service_id': 's1',
        'address': 'Damascus',
        'scheduled_at': '2026-01-01T10:00:00.000Z',
        'status': 'pending',
        'created_at': '2026-01-01T09:00:00.000Z',
      },
      _service,
    );
    expect(legacy.timeType, TimeWindowType.window);
    expect(legacy.scheduledEnd, isNull);
    expect(legacy.windowEnd, legacy.dateTime);
  });
}

class _FakeBookingsDataSource implements BookingsRemoteDataSource {
  final cancelledIds = <String>[];
  final updatedIds = <String>[];
  Map<String, dynamic>? lastUpdatePayload;

  @override
  Future<void> cancelBooking(String bookingId) async {
    cancelledIds.add(bookingId);
  }

  @override
  Future<KlearBooking> updateBooking({
    required String bookingId,
    required Map<String, dynamic> payload,
    required KlearService service,
  }) async {
    updatedIds.add(bookingId);
    lastUpdatePayload = payload;
    return KlearBooking.fromMap(
      {
        ...payload,
        'id': bookingId,
        'customer_id': 'u1',
        'scheduled_at': payload['scheduled_at'],
        'status': 'pending',
        'created_at': '2026-01-01T09:00:00.000Z',
      },
      service,
    );
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