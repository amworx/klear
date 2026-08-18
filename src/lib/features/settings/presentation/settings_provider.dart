import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/settings_repository.dart';
import '../domain/app_settings.dart';

/// Provides the [SettingsRepository].
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => const SettingsRepository(),
);

/// Notifier that holds the current [AppSettings].
///
/// Boots with [AppSettings.defaults] and refreshes from the remote once
/// available. Fetches never throw — on any failure the defaults stay in place
/// so pricing remains deterministic (offline / not configured / tests).
class AppSettingsNotifier extends StateNotifier<AppSettings> {
  AppSettingsNotifier(this._repository) : super(AppSettings.defaults);

  final SettingsRepository _repository;
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      state = await _repository.fetchSettings();
    } catch (_) {
      // Keep defaults; pricing still works offline.
    }
  }

  Future<void> reload() async {
    try {
      state = await _repository.fetchSettings();
    } catch (_) {
      // Keep current settings on transient failure.
    }
  }
}

/// The live app settings. Consumers (breakdown, footer, confirm, order
/// details) watch this so admin price changes take effect immediately.
final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>(
  (ref) {
    final notifier = AppSettingsNotifier(ref.watch(settingsRepositoryProvider));
    notifier.load();
    return notifier;
  },
);