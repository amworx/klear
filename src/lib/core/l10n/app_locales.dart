import 'package:flutter/material.dart';

/// Supported locales. Arabic is the default; English is the fallback.
abstract final class AppLocales {
  static const arabic = Locale('ar');
  static const english = Locale('en');

  static const supported = <Locale>[arabic, english];

  static const fallback = english;

  /// Resolves the effective app locale from the device's preferred locales.
  ///
  /// Uses `platformDispatcher.locales` (the accurate ordered list) rather than
  /// `.locale` which can report a stale default. Returns [arabic] when no
  /// English preference is matched (product default for the primary market).
  static Locale resolve(List<Locale>? deviceLocales) {
    if (deviceLocales == null) return arabic;
    for (final l in deviceLocales) {
      if (l.languageCode == 'en') return english;
      if (l.languageCode == 'ar') return arabic;
    }
    return arabic;
  }
}