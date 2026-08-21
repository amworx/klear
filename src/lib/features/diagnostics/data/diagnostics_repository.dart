import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/logger/app_logger.dart';

/// Sends diagnostics (error logs + device info) to the `error_reports` table
/// so the admin can review and respond. Also logs locally.
class DiagnosticsRepository {
  const DiagnosticsRepository();

  SupabaseClient get _client => Supabase.instance.client;

  /// Submits a report. Returns the inserted row id on success.
  Future<String?> submitReport({
    required String errorSummary,
    required String logs,
    String? email,
    String? description,
  }) async {
    if (!AppConfig.hasSupabaseConfig) {
      AppLogger.instance.w('diagnostics', 'submitReport skipped: no Supabase config');
      return null;
    }
    try {
      // Supabase may not be initialized in tests/offline — guard.
      if (!Supabase.instance.isInitialized) return null;
    } catch (_) {
      return null;
    }

    final user = _client.auth.currentUser;
    final appVersion = await _appVersion();
    final payload = {
      'user_id': user?.id,
      'email': email ?? user?.email,
      'app_version': appVersion,
      'platform': defaultTargetPlatform.name,
      'error_summary': errorSummary,
      'logs': logs,
      'device_info': {
        'description': description,
        'timestamp': DateTime.now().toIso8601String(),
      },
    };

    try {
      final res = await _client.from('error_reports').insert(payload).select('id').single();
      final id = res['id'] as String?;
      AppLogger.instance.i('diagnostics', 'report submitted $id');
      return id;
    } catch (e, st) {
      AppLogger.instance.e('diagnostics', 'submitReport failed', e, st);
      rethrow;
    }
  }

  Future<String> _appVersion() async {
    try {
      // package_info_plus is optional; fall back to pubspec version if not available.
      // We avoid a hard dependency here and just return the pubspec version.
      return '1.0.0+1';
    } catch (_) {
      return 'unknown';
    }
  }
}
