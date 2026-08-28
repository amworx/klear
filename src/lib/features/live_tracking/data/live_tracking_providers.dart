import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bookings/domain/klear_booking.dart';
import '../domain/captain_location.dart';
import 'live_tracking_datasource.dart';

/// Repository/data-source handle for live tracking.
final liveTrackingDataSourceProvider =
    Provider<LiveTrackingDataSource>((ref) => const LiveTrackingDataSource());

/// Live location of a captain serving a given booking.
///
/// Composed per (booking, captain). Starts by fetching the current location,
/// then stays subscribed to realtime so the map marker moves without polling.
/// The stream is cancelled automatically when the screen (or booking) goes
/// away.
///
/// Upstream emissions: the fetched current row (if any), then each realtime
/// UPDATE for the captain's row tied to the tracked booking.
final captainLocationProvider =
    StreamProvider.autoDispose<CaptainLocation>((ref) async* {
  final booking = ref.watch(trackingBookingProvider);
  final providerId = booking?.providerId;
  if (booking == null || providerId == null) {
    return;
  }
  final dataSource = ref.watch(liveTrackingDataSourceProvider);

  // Emit the current row first (reliable initial position).
  final current =
      await dataSource.fetchLocation(providerId: providerId, bookingId: booking.id);
  if (current != null) yield current;

  // Then keep listening to realtime for live updates.
  yield* dataSource.streamLocation(
    providerId: providerId,
    bookingId: booking.id,
  );
});

/// The booking being tracked. Set by the tracking screen; null = inactive.
///
/// `autoDispose` so it resets to null automatically when the tracking screen
/// (the only listener) leaves the tree — avoiding fragile `ref` access in
/// `dispose()`.
final trackingBookingProvider =
    StateProvider.autoDispose<KlearBooking?>((ref) => null);
