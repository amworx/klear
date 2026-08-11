import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../account/presentation/auth_providers.dart';
import '../../bookings/domain/klear_booking.dart';
import '../../bookings/presentation/booking_providers.dart';
import '../../services/presentation/services_providers.dart';

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
