// Widget tests for the live captain-tracking screen.
//
// These pump LiveTrackingPage in isolation with a fake data source so the
// screen can be verified deterministically without a device or network:
// the status banner, the wash-point pin and the live captain marker all
// render once a location arrives.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:klear/core/l10n/app_locales.dart';
import 'package:klear/features/bookings/domain/klear_booking.dart';
import 'package:klear/features/live_tracking/data/live_tracking_datasource.dart';
import 'package:klear/features/live_tracking/data/live_tracking_providers.dart';
import 'package:klear/features/live_tracking/domain/captain_location.dart';
import 'package:klear/features/live_tracking/presentation/live_tracking_page.dart';
import 'package:klear/features/services/domain/klear_service.dart';
import 'package:klear/l10n/app_localizations.dart';

const _service = KlearService(
  id: 's1',
  nameAr: 'غسيل خارجي',
  nameEn: 'Exterior Wash',
  basePrice: 100,
  currency: 'SYP',
  durationMin: 20,
);

KlearBooking _booking(BookingStatus status) => KlearBooking(
      id: 'b-track',
      userId: 'u1',
      serviceId: 's1',
      service: _service,
      address: 'Damascus',
      dateTime: DateTime(2026, 1, 1),
      status: status,
      createdAt: DateTime(2026, 1, 1),
      providerId: 'p1',
      lat: 33.5138,
      lng: 36.2765,
    );

/// Fake data source: returns a fixed/streaming location without touching the
/// network.
class _FakeDataSource extends LiveTrackingDataSource {
  _FakeDataSource(this.locations);
  final List<CaptainLocation> locations;

  @override
  Future<CaptainLocation?> fetchLocation({
    required String providerId,
    required String bookingId,
  }) async {
    return locations.isNotEmpty ? locations.first : null;
  }

  @override
  Stream<CaptainLocation> streamLocation({
    required String providerId,
    required String bookingId,
  }) {
    return Stream.fromIterable(locations);
  }
}

/// In-memory tile provider: returns a 1x1 transparent PNG so the map renders
/// without hitting the (blocked) network in tests.
class _MemoryTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return MemoryImage(base64Decode(_transparentPng));
  }
}

const _transparentPng =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk'
    '+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

Widget _wrap(KlearBooking booking, double lat, double lng) {
  // The page reads the tracking provider to start streaming; seed it so the
  // screen shows live data on first build.
  final location = CaptainLocation(
    providerId: 'p1',
    lat: lat,
    lng: lng,
    activeBookingId: booking.id,
    updatedAt: DateTime(2026, 1, 1, 10, 30),
  );
  return ProviderScope(
    overrides: [
      liveTrackingDataSourceProvider.overrideWithValue(_FakeDataSource([location])),
      trackingBookingProvider.overrideWith((ref) => booking),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocales.supported,
      home: LiveTrackingPage(booking: booking, tileProvider: _MemoryTileProvider()),
    ),
  );
}

void main() {
  testWidgets(
    'renders the status banner and both markers for an on_the_way booking',
    (tester) async {
      tester.binding.platformDispatcher.localesTestValue = const [Locale('en')];
      await tester.pumpWidget(_wrap(_booking(BookingStatus.onTheWay), 33.6, 36.3));
      // Let the initial fetch + stream emit.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // App bar title.
      expect(find.text('Track your captain'), findsOneWidget);
      // Status banner shows "on the way".
      expect(find.text('Your captain is on the way'), findsOneWidget);
      // Wash-point pin and captain marker icons present.
      expect(find.byIcon(Icons.place), findsWidgets);
      expect(find.byIcon(Icons.local_car_wash), findsOneWidget);
    },
  );

  testWidgets('shows waiting hint when no location has arrived yet', (
    tester,
  ) async {
    tester.binding.platformDispatcher.localesTestValue = const [Locale('en')];
    // Empty locations -> nothing emitted.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          liveTrackingDataSourceProvider
              .overrideWithValue(_FakeDataSource(const [])),
          trackingBookingProvider.overrideWith(
            (ref) => _booking(BookingStatus.onTheWay),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocales.supported,
          home: LiveTrackingPage(
            booking: _booking(BookingStatus.onTheWay),
            tileProvider: _MemoryTileProvider(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Waiting hint shows, and the captain marker is absent (no location yet).
    expect(find.textContaining('Waiting for the captain'), findsOneWidget);
    expect(find.byIcon(Icons.local_car_wash), findsNothing);
  });
}
