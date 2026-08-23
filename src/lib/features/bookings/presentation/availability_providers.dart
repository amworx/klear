import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/availability_remote_datasource.dart';
import '../domain/day_availability.dart';

/// Provides the availability datasource.
final availabilityDataSourceProvider = Provider<AvailabilityRemoteDataSource>(
  (ref) => const AvailabilityRemoteDataSource(),
);

/// Availability for a consecutive range of days, keyed by (from, days).
///
/// The booking flow uses a single range covering the whole calendar strip
/// (today + 13), so one network call feeds both the strip's load dots and
/// the selected-day window pills. `autoDispose` keeps stale data from
/// leaking between booking sessions; the flow invalidates on entry anyway.
final availabilityRangeProvider = FutureProvider.autoDispose
    .family<List<DayAvailability>, ({DateTime from, int days})>(
  (ref, range) async {
    final ds = ref.watch(availabilityDataSourceProvider);
    return ds.fetchRange(fromDay: range.from, days: range.days);
  },
);
