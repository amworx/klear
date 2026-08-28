import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../account/presentation/auth_providers.dart';
import '../../bookings/domain/booking_insights.dart';
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
            booking.status == BookingStatus.accepted ||
            booking.status == BookingStatus.onTheWay ||
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

/// Personalization signals (T3): most-used service, last booking and
/// preferred time window — derived purely from booking history. Null while
/// history is still loading.
final bookingInsightsProvider = Provider<BookingInsights?>((ref) {
  final bookings = ref.watch(myBookingsProvider).valueOrNull;
  if (bookings == null) return null;
  // Catalog order is only needed for most-used tie-breaking; fall back to
  // an empty list when the catalog hasn't loaded yet.
  final catalog = ref.watch(servicesProvider).valueOrNull ?? const [];
  return BookingInsights.compute(bookings, catalog);
});
