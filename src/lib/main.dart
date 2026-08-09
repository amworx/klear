import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/l10n/locale_controller.dart';
import 'core/network/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load persisted preferences once, then hand them to the locale notifier.
  LocaleNotifier.prefs = await SharedPreferences.getInstance();
  await SupabaseClientManager.init();
  runApp(
    const ProviderScope(child: KlearApp()),
  );
}