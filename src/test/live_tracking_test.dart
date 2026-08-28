// Tests for live-tracking: CaptainLocation parsing and the BookingStatus
// helpers that gate the "Track your captain" feature (accepted/on_the_way).
import 'package:flutter_test/flutter_test.dart';

import 'package:klear/features/bookings/domain/klear_booking.dart';
import 'package:klear/features/live_tracking/domain/captain_location.dart';
import 'package:klear/features/services/domain/klear_service.dart';

const _service = KlearService(
  id: 's1',
  nameAr: 'غسيل خارجي',
  nameEn: 'Exterior Wash',
  basePrice: 100,
  currency: 'SYP',
  durationMin: 20,
);

KlearBooking bookingWith(
  BookingStatus status, {
  String? providerId,
  double? lat,
  double? lng,
}) =>
    KlearBooking(
      id: 'b1',
      userId: 'u1',
      serviceId: 's1',
      service: _service,
      address: 'A',
      dateTime: DateTime(2026, 1, 1),
      status: status,
      createdAt: DateTime(2026, 1, 1),
      providerId: providerId,
      lat: lat,
      lng: lng,
    );

void main() {
  group('KlearBooking.canTrack', () {
    test('true only when captain assigned + active status + wash coords', () {
      // Fully trackable: on the way with captain and coordinates.
      expect(
        bookingWith(
          BookingStatus.onTheWay,
          providerId: 'p1',
          lat: 33.5,
          lng: 36.2,
        ).canTrack,
        isTrue,
      );
      expect(
        bookingWith(
          BookingStatus.inProgress,
          providerId: 'p1',
          lat: 33.5,
          lng: 36.2,
        ).canTrack,
        isTrue,
      );
      // Not yet assigned / not active: cannot track.
      expect(
        bookingWith(
          BookingStatus.pending,
          providerId: 'p1',
          lat: 33.5,
          lng: 36.2,
        ).canTrack,
        isFalse,
      );
      expect(
        bookingWith(
          BookingStatus.accepted,
          providerId: 'p1',
          lat: 33.5,
          lng: 36.2,
        ).canTrack,
        isFalse,
      );
      expect(
        bookingWith(
          BookingStatus.completed,
          providerId: 'p1',
          lat: 33.5,
          lng: 36.2,
        ).canTrack,
        isFalse,
      );
      // Missing pieces: no captain or no coordinates -> not trackable.
      expect(
        bookingWith(BookingStatus.onTheWay, lat: 33.5, lng: 36.2).canTrack,
        isFalse,
      );
      expect(
        bookingWith(BookingStatus.onTheWay, providerId: 'p1').canTrack,
        isFalse,
      );
    });
  });

  group('KlearBooking fromMap status parsing', () {
    test('parses the new on_the_way and accepted db values', () {
      expect(
        KlearBooking.fromMap(_map('on_the_way'), _service).status,
        BookingStatus.onTheWay,
      );
      expect(
        KlearBooking.fromMap(_map('accepted'), _service).status,
        BookingStatus.accepted,
      );
      expect(
        KlearBooking.fromMap(_map('in_progress'), _service).status,
        BookingStatus.inProgress,
      );
    });

    test('preserves provider_id from the raw row', () {
      final raw = _map('on_the_way')..['provider_id'] = 'p-9';
      expect(KlearBooking.fromMap(raw, _service).providerId, 'p-9');
    });
  });

  group('CaptainLocation.fromMap', () {
    test('maps provider, coords, booking and timestamp', () {
      final loc = CaptainLocation.fromMap(const {
        'provider_id': 'p1',
        'lat': 33.5138,
        'lng': 36.2765,
        'active_booking_id': 'b1',
        'updated_at': '2026-08-27T10:30:00',
      });
      expect(loc.providerId, 'p1');
      expect(loc.lat, 33.5138);
      expect(loc.lng, 36.2765);
      expect(loc.activeBookingId, 'b1');
      expect(loc.updatedAt, isNotNull);
    });

    test('tolerates missing optional fields', () {
      final loc = CaptainLocation.fromMap(const {
        'provider_id': 'p1',
        'lat': 33.5,
        'lng': 36.2,
      });
      expect(loc.activeBookingId, isNull);
      expect(loc.updatedAt, isNotNull);
    });
  });
}

Map<String, dynamic> _map(String rawStatus) => {
      'id': 'b1',
      'customer_id': 'u1',
      'service_id': 's1',
      'address': 'A',
      'scheduled_at': '2026-01-01T10:00:00',
      'status': rawStatus,
      'created_at': '2026-01-01T10:00:00',
    };
