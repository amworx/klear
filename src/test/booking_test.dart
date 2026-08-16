// Tests for the booking flow state and Riverpod providers.
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
}