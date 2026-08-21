import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_update_service.dart';

/// Holds the result of the last update check.
class AppUpdateState {
  const AppUpdateState({
    this.info,
    this.currentVersion,
    this.isLoading = false,
    this.error,
  });

  final AppUpdateInfo? info;
  final String? currentVersion;
  final bool isLoading;
  final String? error;

  bool get hasUpdate {
    if (info == null || currentVersion == null) return false;
    return AppUpdateService.isUpdateAvailable(currentVersion!, info!.latestVersion);
  }

  bool get isForceUpdate {
    if (info == null || currentVersion == null) return false;
    return AppUpdateService.isForceUpdateRequired(currentVersion!, info!.minimumVersion) ||
        info!.forceUpdate && hasUpdate;
  }
}

class AppUpdateNotifier extends StateNotifier<AppUpdateState> {
  AppUpdateNotifier() : super(const AppUpdateState(isLoading: true)) {
    check();
  }

  final _service = const AppUpdateService();

  Future<void> check() async {
    state = const AppUpdateState(isLoading: true);
    try {
      final current = await _service.currentVersion();
      final info = await _service.fetchLatest();
      state = AppUpdateState(info: info, currentVersion: current, isLoading: false);
    } catch (e) {
      state = AppUpdateState(isLoading: false, error: e.toString());
    }
  }

  Future<bool> launchUpdate() async {
    final url = state.info?.updateUrl;
    if (url == null) return false;
    return _service.launchUpdate(url);
  }
}

final appUpdateProvider = StateNotifierProvider<AppUpdateNotifier, AppUpdateState>((ref) {
  return AppUpdateNotifier();
});
