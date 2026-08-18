import '../../../core/network/supabase_service.dart';
import '../domain/app_settings.dart';

/// Remote datasource for the single-row `app_settings` configuration.
class SettingsRemoteDataSource {
  const SettingsRemoteDataSource();

  /// Fetches the current pricing/operations settings.
  ///
  /// Returns [AppSettings.defaults] when Supabase is not configured (graceful
  /// offline mode) or the row is missing.
  Future<AppSettings> fetchSettings() async {
    if (!SupabaseClientManager.isReady) return AppSettings.defaults;

    final response = await SupabaseClientManager.instance.client
        .from('app_settings')
        .select()
        .maybeSingle();

    if (response == null) return AppSettings.defaults;
    return AppSettings.fromMap(Map<String, dynamic>.from(response));
  }
}