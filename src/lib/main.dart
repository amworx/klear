import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';
import 'core/l10n/locale_controller.dart';
import 'core/logger/app_logger.dart';
import 'core/network/supabase_service.dart';
import 'core/theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final logger = AppLogger.instance;
  // Capture every uncaught Flutter / platform error so the in-app log viewer
  // (Account → Diagnostics) and `adb logcat` always have the full context.
  FlutterError.onError = (details) {
    logger.e('flutter', details.exceptionAsString(), details.exception, details.stack);
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    logger.e('platform', error.toString(), error, stack);
    return false;
  };

  if (!AppConfig.hasSupabaseConfig) {
    logger.w('config', 'App built without SUPABASE_URL / SUPABASE_PUBLISHABLE_KEY — showing misconfigured screen');
  } else {
    logger.i('config', 'Supabase config present, initializing');
  }

  // Load persisted preferences once, then hand them to the notifiers that
  // read them (locale + theme).
  final prefs = await SharedPreferences.getInstance();
  LocaleNotifier.prefs = prefs;
  ThemeController.prefs = prefs;
  await SupabaseClientManager.init();
  logger.i('app', 'Supabase init complete (isReady=${SupabaseClientManager.isReady})');
  runApp(
    ProviderScope(
      child: AppConfig.hasSupabaseConfig
          ? const KlearApp()
          : const _MisconfiguredBuildApp(),
    ),
  );
}

/// Shown when the app was built without the required `--dart-define`
/// backend configuration (SUPABASE_URL / SUPABASE_PUBLISHABLE_KEY).
///
/// Without this guard such builds start in a broken placeholder mode and
/// only fail later with a cryptic `LateInitializationError` on the first
/// auth or data call. Developer-facing by design; correct builds never see
/// it.
class _MisconfiguredBuildApp extends StatelessWidget {
  const _MisconfiguredBuildApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.settings_suggest_rounded,
                  size: 64,
                  color: Colors.orange.shade700,
                ),
                const SizedBox(height: 24),
                Text(
                  'Build is missing backend configuration',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                const Text(
                  'This APK was built without Supabase credentials, so '
                  'sign-in and all data features are disabled.\n\n'
                  'Rebuild with:\n'
                  '--dart-define=SUPABASE_URL=<your-project-url>\n'
                  '--dart-define=SUPABASE_PUBLISHABLE_KEY=<publishable-key>',
                  style: TextStyle(height: 1.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}