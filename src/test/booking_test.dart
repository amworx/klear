// Tests for the booking flow state and Riverpod providers.
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:klear/features/bookings/presentation/booking_providers.dart';

void main() {
  testWidgets('Booking draft state persists across screens', (tester) async {
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
}
