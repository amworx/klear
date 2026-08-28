import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_service.dart';
import '../domain/captain_location.dart';

/// Data source for captain live locations.
///
/// Tracks the `captain_locations` table (published to realtime). A customer is
/// only allowed to see a captain's row while their booking with that captain is
/// active — both for the initial fetch and for realtime events (RLS applies on
/// the authenticated realtime channel).
class LiveTrackingDataSource {
  const LiveTrackingDataSource();

  /// Fetch the captain's most recent location for an active booking.
  Future<CaptainLocation?> fetchLocation({
    required String providerId,
    required String bookingId,
  }) async {
    if (!SupabaseClientManager.isReady) return null;
    final rows = await SupabaseClientManager.instance.client
        .from('captain_locations')
        .select()
        .eq('provider_id', providerId)
        .eq('active_booking_id', bookingId)
        .maybeSingle();
    if (rows == null) return null;
    return CaptainLocation.fromMap(Map<String, dynamic>.from(rows));
  }

  /// Stream live updates for a captain's location while they serve a booking.
  ///
  /// The customer subscribes with the booking id so only the captain row tied
  /// to their booking is reported back by RLS-filtered realtime.
  Stream<CaptainLocation> streamLocation({
    required String providerId,
    required String bookingId,
  }) {
    final controller = StreamController<CaptainLocation>.broadcast();
    final client = SupabaseClientManager.instance.client;
    // Unique channel per captain+booking to avoid cross-talk.
    final channel = client
        .channel('tracking:$providerId:$bookingId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'captain_locations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'provider_id',
            value: providerId,
          ),
          callback: (payload) {
            final newRecord = payload.newRecord;
            final loc = CaptainLocation.fromMap(
              Map<String, dynamic>.from(newRecord),
            );
            // Only forward updates for the active booking.
            if (loc.activeBookingId == bookingId) {
              controller.add(loc);
            }
          },
        )
        .subscribe();

    controller.onCancel = () async {
      await client.removeChannel(channel);
    };
    return controller.stream;
  }
}
