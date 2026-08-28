import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../app/app_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../bookings/domain/klear_booking.dart';
import '../data/live_tracking_providers.dart';
import '../domain/captain_location.dart';

/// Live tracking screen.
///
/// Renders a map with the wash point (from the booking) and the captain's live
/// GPS position. The captain marker moves in real time via the
/// `captain_locations` realtime stream. The view auto-fits to show both the
/// captain and the destination, and recenters/re-fits as the captain moves.
class LiveTrackingPage extends ConsumerStatefulWidget {
  const LiveTrackingPage({
    super.key,
    required this.booking,
    this.tileProvider,
  });

  final KlearBooking booking;

  /// Optional tile source. Defaults to the real OSM `NetworkTileProvider`;
  /// tests inject an in-memory provider to avoid network access.
  final TileProvider? tileProvider;

  @override
  ConsumerState<LiveTrackingPage> createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends ConsumerState<LiveTrackingPage> {
  final _mapController = MapController();
  final _washPoint = LatLng(33.5138, 36.2765); // Damascus fallback.

  @override
  void initState() {
    super.initState();
    // Equip the shared tracking provider with this booking.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(trackingBookingProvider.notifier).state = widget.booking;
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _fit(LatLng captainPos, LatLng washPoint) {
    try {
      final bounds = LatLngBounds.fromPoints([washPoint, captainPos]);
      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(48)),
      );
    } catch (_) {
      // Ignore camera-fit failures (e.g. identical points).
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final booking = widget.booking;

    // Initial wash-point from the booking, if present.
    final washPoint = (booking.lat != null && booking.lng != null)
        ? LatLng(booking.lat!, booking.lng!)
        : _washPoint;

    // Recenter/fit the camera to include the captain and the wash point
    // whenever a new location arrives (first load included).
    ref.listen<AsyncValue<CaptainLocation>>(captainLocationProvider, (prev, next) {
      final loc = next.value;
      if (loc != null) {
        _fit(LatLng(loc.lat, loc.lng), washPoint);
      }
    });

    final capLocAsync = ref.watch(captainLocationProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.trackCaptain),
        actions: [
          IconButton(
            tooltip: l10n.chatWithCaptain,
            icon: const Icon(Icons.chat_outlined),
            onPressed: () => context.push(KlearRoutes.chat, extra: booking.id),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: washPoint,
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.klear.klear',
                tileProvider: widget.tileProvider ?? NetworkTileProvider(),
              ),
              MarkerLayer(
                markers: [
                  // Wash point / destination pin.
                  Marker(
                    point: washPoint,
                    width: 44,
                    height: 44,
                    child: Icon(Icons.place, size: 44, color: scheme.primary),
                  ),
                  // Captain's live marker (only when we have a location).
                  if (capLocAsync.value != null)
                    Marker(
                      point: LatLng(
                        capLocAsync.value!.lat,
                        capLocAsync.value!.lng,
                      ),
                      width: 48,
                      height: 48,
                      child: _captainMarker(scheme),
                    ),
                ],
              ),
            ],
          ),
          // Top status chip: which phase the captain is in.
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: _StatusBanner(
              status: booking.status,
              onTheWay: l10n.captainOnTheWay,
              washing: l10n.captainWashing,
              live: l10n.trackingLive,
              scheme: scheme,
            ),
          ),
          // Bottom sheet: captain location + last-update meta.
          Align(
            alignment: Alignment.bottomCenter,
            child: _LocationSheet(
              async: capLocAsync,
              washPointLabel: l10n.washPoint,
              lastSeenLabel: l10n.captainLastSeen,
              waitingLabel: l10n.trackWaitingForLocation,
            ),
          ),
        ],
      ),
    );
  }

  Widget _captainMarker(ColorScheme scheme) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: scheme.primary,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 8),
        ],
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.local_car_wash, size: 22, color: Colors.white),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.status,
    required this.onTheWay,
    required this.washing,
    required this.live,
    required this.scheme,
  });

  final BookingStatus status;
  final String onTheWay;
  final String washing;
  final String live;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final text = switch (status) {
      BookingStatus.onTheWay => onTheWay,
      BookingStatus.inProgress => washing,
      _ => live,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status == BookingStatus.inProgress
                ? Icons.cleaning_services
                : Icons.directions_car,
            color: scheme.primary,
          ),
          const SizedBox(width: 8),
          Flexible(child: Text(text, style: Theme.of(context).textTheme.titleSmall)),
        ],
      ),
    );
  }
}

class _LocationSheet extends StatelessWidget {
  const _LocationSheet({
    required this.async,
    required this.washPointLabel,
    required this.lastSeenLabel,
    required this.waitingLabel,
  });

  final AsyncValue<CaptainLocation> async;
  final String washPointLabel;
  final String lastSeenLabel;
  final String waitingLabel;

  @override
  Widget build(BuildContext context) {
    final loc = async.value;
    final lastSeen = loc == null
        ? waitingLabel
        : '$lastSeenLabel: ${_formatTime(loc.updatedAt)}';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.gps_fixed),
              const SizedBox(width: 8),
              Text(washPointLabel,
                  style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
          Text(lastSeen, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  String _formatTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
