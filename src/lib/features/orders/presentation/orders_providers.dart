import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../account/presentation/auth_providers.dart';
import '../../bookings/domain/klear_booking.dart';
import '../../bookings/presentation/booking_providers.dart';
import '../../services/presentation/services_providers.dart';

/// Orders screen filter tabs.
enum OrdersFilter {
  /// Active bookings: pending, confirmed or in progress.
  current,
  /// Completed bookings.
  finished,
  /// Cancelled bookings.
  cancelled,
}

extension OrdersFilterX on OrdersFilter {
  bool matches(KlearBooking booking) {
    return switch (this) {
      OrdersFilter.current =>
        booking.status == BookingStatus.pending ||
            booking.status == BookingStatus.confirmed ||
            booking.status == BookingStatus.inProgress,
      OrdersFilter.finished => booking.status == BookingStatus.completed,
      OrdersFilter.cancelled => booking.status == BookingStatus.cancelled,
    };
  }
}

/// The signed-in user's bookings, newest first.
final myBookingsProvider = FutureProvider<List<KlearBooking>>((ref) async {
  final auth = ref.watch(authProvider);
  final userId = auth.user?.id;
  if (userId == null) return const [];

  final services = await ref.watch(servicesProvider.future);
  final servicesById = {
    for (final service in services) service.id: service,
  };

  return ref.read(bookingRepositoryProvider).getMyBookings(
        userId: userId,
        servicesById: servicesById,
      );
});
