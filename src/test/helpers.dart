// Shared test utilities for pumping the full Klear app.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:klear/app/klear_app.dart';
import 'package:klear/core/l10n/locale_controller.dart';

/// Builds a [KlearApp] in a [ProviderScope] with an in-memory prefs backend,
/// mirroring how `main()` composes the app.
Future<Widget> buildKlearApp() async {
  SharedPreferences.setMockInitialValues({});
  LocaleNotifier.prefs = await SharedPreferences.getInstance();
  return const ProviderScope(child: KlearApp());
}