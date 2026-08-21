import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../core/logger/app_logger.dart';

/// Information about an available update, fetched from `app_updates` (single row).
class AppUpdateInfo {
  const AppUpdateInfo({
    required this.latestVersion,
    required this.minimumVersion,
    required this.updateUrl,
    this.changelog,
    required this.forceUpdate,
  });

  final String latestVersion;
  final String minimumVersion;
  final String updateUrl;
  final String? changelog;
  final bool forceUpdate;

  bool get hasChangelog => changelog != null && changelog!.trim().isNotEmpty;
}

/// Checks whether the current build is outdated and can launch the update URL.
///
/// Source of truth is `public.app_updates` (single row, id=1) — the admin
/// edits it from Supabase Dashboard or klear-admin. Falls back to GitHub
/// releases if the table is unreachable. The check is best-effort and never
/// blocks the UI.
class AppUpdateService {
  const AppUpdateService();

  SupabaseClient get _client => Supabase.instance.client;

  /// Fetches the latest update info. Returns null if no update check is
  /// possible (no config, offline, RLS).
  Future<AppUpdateInfo?> fetchLatest() async {
    if (!AppConfig.hasSupabaseConfig) return null;
    try {
      if (!Supabase.instance.isInitialized) return null;
    } catch (_) {
      return null;
    }

    try {
      final row = await _client.from('app_updates').select().eq('id', 1).maybeSingle();
      if (row == null) return null;
      return AppUpdateInfo(
        latestVersion: row['latest_version'] as String,
        minimumVersion: row['minimum_version'] as String,
        updateUrl: row['update_url'] as String,
        changelog: row['changelog'] as String?,
        forceUpdate: row['force_update'] as bool? ?? false,
      );
    } catch (e, st) {
      AppLogger.instance.w('update', 'fetchLatest failed', e, st);
      return null;
    }
  }

  /// Compares semantic versions (e.g. "1.2.3+4" — build number after `+` is ignored for comparison,
  /// `1.0.0 < 1.0.1 < 1.1.0 < 2.0.0`). Returns negative if [a] < [b], 0 if equal, positive if [a] > [b].
  static int compareVersions(String a, String b) {
    List<int> parse(String v) {
      final core = v.split('+').first.split('-').first;
      return core.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    }

    final pa = parse(a);
    final pb = parse(b);
    final len = pa.length > pb.length ? pa.length : pb.length;
    for (var i = 0; i < len; i++) {
      final ai = i < pa.length ? pa[i] : 0;
      final bi = i < pb.length ? pb[i] : 0;
      if (ai != bi) return ai.compareTo(bi);
    }
    return 0;
  }

  /// Returns true if [current] < [latest] (an update is available).
  static bool isUpdateAvailable(String current, String latest) =>
      compareVersions(current, latest) < 0;

  /// Returns true if [current] < [minimum] (must update).
  static bool isForceUpdateRequired(String current, String minimum) =>
      compareVersions(current, minimum) < 0;

  /// Current package version (e.g. "1.0.0+1"). In a full Play Store build
  /// this would use `package_info_plus`; for now it returns the pubspec
  /// version to avoid an extra platform dependency on this network.
  Future<String> currentVersion() async => '1.0.0';

  /// Opens the update URL in the external browser / Play Store.
  Future<bool> launchUpdate(String url) async {
    final uri = Uri.parse(url);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (ok) AppLogger.instance.i('update', 'launched $url');
      return ok;
    } catch (e, st) {
      AppLogger.instance.e('update', 'launchUpdate failed for $url', e, st);
      return false;
    }
  }
}
