import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted app theme choice (light / dark / follow system).
///
/// Mirrors [LocaleNotifier]'s pattern: prefs are injected once before
/// `runApp` (see `main()`); the system default is used until the user picks
/// an explicit mode from their Profile screen.
class ThemeController extends Notifier<ThemeMode> {
  static const _kPrefKey = 'app_theme';

  /// Injected before `runApp` (see `main()`); never accessed before then.
  static SharedPreferences? prefs;

  @override
  ThemeMode build() {
    final saved = prefs?.getString(_kPrefKey);
    return switch (saved) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  /// Applies and persists the theme mode.
  Future<void> setMode(ThemeMode mode) async {
    if (mode == state) return;
    state = mode;
    await prefs?.setString(_kPrefKey, mode.name);
  }
}

/// Riverpod provider exposing the mutable theme choice.
final themeControllerProvider = NotifierProvider<ThemeController, ThemeMode>(
  ThemeController.new,
);
