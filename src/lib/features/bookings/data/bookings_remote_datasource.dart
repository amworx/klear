import '../../../core/network/supabase_service.dart';
import '../../services/domain/klear_service.dart';
import '../domain/klear_booking.dart';

/// Remote datasource for bookings backed by Supabase.
class BookingsRemoteDataSource {
  const BookingsRemoteDataSource();

  /// Insert a confirmed booking row.
  ///
  /// `extra` carries fields not part of the domain map (car_id).
  Future<KlearBooking> createBooking({
    required Map<String, dynamic> payload,
    required KlearService service,
  }) async {
    if (!SupabaseClientManager.isReady) {
      throw StateError('Supabase is not configured');
    }

    final response = await SupabaseClientManager.instance.client
        .from('bookings')
        .insert(payload)
        .select()
        .single();

    return KlearBooking.fromMap(Map<String, dynamic>.from(response), service);
  }

  /// Fetch the current user's bookings (newest first).
  Future<List<KlearBooking>> fetchMyBookings({
    required String userId,
    required Map<String, KlearService> servicesById,
  }) async {
    if (!SupabaseClientManager.isReady) return const [];

    final response = await SupabaseClientManager.instance.client
        .from('bookings')
        .select()
        .eq('customer_id', userId)
        .order('scheduled_at', ascending: false);

    return response
        .map((row) {
          final map = Map<String, dynamic>.from(row);
          final service =
              servicesById[map['service_id']?.toString()] ?? KlearService.unknown;
          return KlearBooking.fromMap(map, service);
        })
        .toList();
  }

  /// Cancels a booking (status -> 'cancelled'). RLS restricts the update to
  /// the booking's owner.
  Future<void> cancelBooking(String bookingId) async {
    if (!SupabaseClientManager.isReady) return;

    await SupabaseClientManager.instance.client
        .from('bookings')
        .update({'status': 'cancelled'})
        .eq('id', bookingId);
  }
}