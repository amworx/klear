import '../../../core/network/supabase_service.dart';
import '../domain/day_availability.dart';

/// Remote datasource for slot availability backed by the
/// `availability_range` Postgres RPC (aggregate counts only — RLS-safe).
class AvailabilityRemoteDataSource {
  const AvailabilityRemoteDataSource();

  /// Fetches availability for [days] consecutive days starting [fromDay].
  /// Both arguments are date-only.
  Future<List<DayAvailability>> fetchRange({
    required DateTime fromDay,
    required int days,
  }) async {
    if (!SupabaseClientManager.isReady) return const [];

    final from = DateTime(fromDay.year, fromDay.month, fromDay.day);
    final response = await SupabaseClientManager.instance.client.rpc(
      'availability_range',
      params: {
        'from_day': _ymd(from),
        'days': days,
      },
    );

    return DayAvailability.listFromRows(response as List<dynamic>);
  }

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
