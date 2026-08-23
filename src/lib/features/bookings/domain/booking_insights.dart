import 'klear_booking.dart';
import '../../services/domain/klear_service.dart';
import '../../cars/domain/klear_car.dart';

/// A user's preferred scheduling pattern derived from booking history:
/// flexibility type plus, for fixed windows, the start hour bucket
/// (8 / 12 / 16). Used as a smart default when scheduling.
typedef WindowPreference = (TimeWindowType, int?);

/// Pure aggregation over a user's booking history. No Flutter, no I/O —
/// trivially unit-testable (T3).
class BookingInsights {
  const BookingInsights({
    this.mostUsedServiceId,
    this.lastBooking,
    this.preferredWindow,
  });

  /// Service booked most often across non-cancelled history.
  /// Ties resolve to the service appearing first in the active catalog.
  final String? mostUsedServiceId;

  /// Most recently CREATED booking (the honest "what did I last order"),
  /// regardless of its scheduled date.
  final KlearBooking? lastBooking;

  /// Modal (timeType, start-hour) combination across non-cancelled history.
  /// Hour is only meaningful for fixed windows; ties go to the most recent
  /// usage. Null when there is no history.
  final WindowPreference? preferredWindow;

  /// Computes insights from [bookings], using [catalog] (active services,
  /// in display order) only for tie-breaking [mostUsedServiceId].
  factory BookingInsights.compute(
    List<KlearBooking> bookings,
    List<KlearService> catalog,
  ) {
    if (bookings.isEmpty) return const BookingInsights();

    final kept =
        bookings.where((b) => b.status != BookingStatus.cancelled).toList();
    if (kept.isEmpty) return const BookingInsights();

    // --- Most used service -------------------------------------------
    // Count per service id, then pick argmax with catalog-order tie-break.
    final counts = <String, int>{};
    for (final b in kept) {
      counts[b.serviceId] = (counts[b.serviceId] ?? 0) + 1;
    }
    final catalogIndex = {
      for (final (i, s) in catalog.indexed) s.id: i,
    };
    String? mostUsed;
    var bestCount = 0;
    var bestRank = 1 << 30;
    counts.forEach((id, count) {
      // Larger count wins; equal counts defer to the earlier catalog
      // position (ids missing from the catalog rank last via sentinel).
      final rank = catalogIndex[id] ?? (1 << 20);
      if (count > bestCount || (count == bestCount && rank < bestRank)) {
        mostUsed = id;
        bestCount = count;
        bestRank = rank;
      }
    });

    // --- Last booking -------------------------------------------------
    KlearBooking last = kept.first;
    for (final b in kept.skip(1)) {
      if (b.createdAt.isAfter(last.createdAt)) last = b;
    }

    // --- Preferred window ---------------------------------------------
    // Mode of (timeType, hour); hour kept null for all-day/urgent where it
    // carries no meaning. Ties -> most recent createdAt wins.
    final windowCounts = <String, int>{};
    final windowKeys = <String, WindowPreference>{};
    var bestWindowKey = '';
    var bestWindowCount = 0;
    for (final b in (kept.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt)))) {
      final hour = b.timeType == TimeWindowType.window ? b.dateTime.hour : null;
      final key = '${b.timeType.name}|$hour';
      final c = (windowCounts[key] ?? 0) + 1;
      windowCounts[key] = c;
      windowKeys[key] = (b.timeType, hour);
      if (c >= bestWindowCount) {
        bestWindowCount = c;
        bestWindowKey = key;
      }
    }

    return BookingInsights(
      mostUsedServiceId: mostUsed,
      lastBooking: last,
      preferredWindow: bestWindowCount > 0 ? windowKeys[bestWindowKey] : null,
    );
  }

  /// Builds a ready-to-confirm draft from the last booking: same service,
  /// car, address, coordinates and time window. Returns null when the
  /// booking's service is no longer active in the catalog.
  static BookingDraft? rebookDraft(
    KlearBooking last, {
    required List<KlearService> activeServices,
    KlearCar? car,
  }) {
    final service = activeServices
        .where((s) => s.id == last.serviceId)
        .firstOrNull;
    if (service == null) return null;
    return BookingDraft(
      service: service,
      car: car,
      address: last.address,
      lat: last.lat,
      lng: last.lng,
      dateTime: last.dateTime,
      timeType: last.timeType,
      scheduledEnd: last.scheduledEnd,
      notes: last.notes,
    );
  }
}
