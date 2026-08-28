/// A captain's live location shared via the `captain_locations` table.
///
/// RLS guarantees the reading customer can only see this row when they have
/// an active booking (on_the_way / in_progress) with that captain, so any
/// location we receive here is intentionally meant for us.
class CaptainLocation {
  const CaptainLocation({
    required this.providerId,
    required this.lat,
    required this.lng,
    required this.activeBookingId,
    required this.updatedAt,
  });

  final String providerId;
  final double lat;
  final double lng;

  /// The booking this captain is currently servicing.
  final String? activeBookingId;
  final DateTime updatedAt;

  factory CaptainLocation.fromMap(Map<String, dynamic> map) {
    return CaptainLocation(
      providerId: map['provider_id']?.toString() ?? '',
      lat: (map['lat'] as num?)?.toDouble() ?? 0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0,
      activeBookingId: map['active_booking_id']?.toString(),
      updatedAt:
          DateTime.tryParse(map['updated_at']?.toString() ?? '')?.toLocal() ??
              DateTime.now(),
    );
  }
}
