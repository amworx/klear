import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_locales.dart';

/// Persisted app-language choice.
///
/// Arabic is the default for the primary (Arab) market and is never chosen
/// implicitly from the device locale. English is only used when the user
/// explicitly opts into it via the in-app language toggle.
class LocaleNotifier extends Notifier<Locale> {
  static const _kPrefKey = 'app_locale';

  /// Injected before `runApp` (see `main()`); never accessed before then.
  static SharedPreferences? prefs;

  @override
  Locale build() {
    final saved = prefs?.getString(_kPrefKey);
    return (saved == 'en') ? AppLocales.english : AppLocales.arabic;
  }

  bool get isArabic => state == AppLocales.arabic;

  /// Switches the app language. 'ar' → Arabic; anything else → English.
  Future<void> setLocale(Locale locale) async {
    if (locale == state) return;
    state = locale;
    await prefs?.setString(_kPrefKey, locale.languageCode);
  }
}

/// Riverpod provider exposing the mutable language choice.
///
/// A [NotifierProvider] so consumers rebuild on every `setLocale` change.
final localeControllerProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);