// Tests for the orders filter tabs (Current / Finished / Cancelled).
import 'package:flutter_test/flutter_test.dart';

import 'package:klear/features/bookings/domain/klear_booking.dart';
import 'package:klear/features/orders/presentation/orders_providers.dart';
import 'package:klear/features/services/domain/klear_service.dart';

const _service = KlearService(
  id: 's1',
  nameAr: 'غسيل خارجي',
  nameEn: 'Exterior Wash',
  basePrice: 100,
  currency: 'SYP',
  durationMin: 20,
);

KlearBooking bookingWith(BookingStatus status) => KlearBooking(
      id: 'b-${status.name}',
      userId: 'u1',
      serviceId: 's1',
      service: _service,
      address: 'A',
      dateTime: DateTime(2026, 1, 1),
      status: status,
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  test('current tab matches assigned/active statuses (pending..in-progress)', () {
    expect(OrdersFilter.current.matches(bookingWith(BookingStatus.pending)), isTrue);
    expect(
      OrdersFilter.current.matches(bookingWith(BookingStatus.accepted)),
      isTrue,
    );
    expect(
      OrdersFilter.current.matches(bookingWith(BookingStatus.onTheWay)),
      isTrue,
    );
    expect(
      OrdersFilter.current.matches(bookingWith(BookingStatus.inProgress)),
      isTrue,
    );
    expect(
      OrdersFilter.current.matches(bookingWith(BookingStatus.completed)),
      isFalse,
    );
    expect(
      OrdersFilter.current.matches(bookingWith(BookingStatus.cancelled)),
      isFalse,
    );
  });

  test('finished tab matches only completed bookings', () {
    expect(OrdersFilter.finished.matches(bookingWith(BookingStatus.pending)), isFalse);
    expect(
      OrdersFilter.finished.matches(bookingWith(BookingStatus.inProgress)),
      isFalse,
    );
    expect(
      OrdersFilter.finished.matches(bookingWith(BookingStatus.completed)),
      isTrue,
    );
    expect(
      OrdersFilter.finished.matches(bookingWith(BookingStatus.cancelled)),
      isFalse,
    );
  });

  test('cancelled tab matches only cancelled bookings', () {
    expect(
      OrdersFilter.cancelled.matches(bookingWith(BookingStatus.cancelled)),
      isTrue,
    );
    expect(
      OrdersFilter.cancelled.matches(bookingWith(BookingStatus.completed)),
      isFalse,
    );
    expect(
      OrdersFilter.cancelled.matches(bookingWith(BookingStatus.pending)),
      isFalse,
    );
  });

  test('every booking status lands in exactly one tab', () {
    for (final status in BookingStatus.values) {
      final matches = OrdersFilter.values
          .where((filter) => filter.matches(bookingWith(status)))
          .toList();
      expect(matches.length, 1, reason: 'Status $status must match one tab');
    }
  });
}
