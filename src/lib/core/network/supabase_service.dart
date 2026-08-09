import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

/// Central Supabase client access.
///
/// `Supabase.instance.client` is available after [SupabaseClient.init] is
/// called from `main()`. This class centralizes that bootstrap.
abstract final class SupabaseClientManager {
  static bool _initialized = false;

  /// Idempotent initializer. Call once from `main()` before runApp.
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    if (!AppConfig.hasSupabaseConfig) {
      // Graceful offline/placeholder mode: the app still runs without
      // a backend, and feature screens surface a config hint.
      // Do not throw; allow UI to render for early development.
      return;
    }

    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabasePublishableKey,
    );
  }

  static Supabase get instance => Supabase.instance;
  static bool get isReady => AppConfig.hasSupabaseConfig;
}