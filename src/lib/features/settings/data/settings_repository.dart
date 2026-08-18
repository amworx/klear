import '../domain/app_settings.dart';
import 'settings_remote_datasource.dart';

/// Repository for app settings (single source of truth in the Data layer).
class SettingsRepository {
  const SettingsRepository({this.remote = const SettingsRemoteDataSource()});

  final SettingsRemoteDataSource remote;

  Future<AppSettings> fetchSettings() => remote.fetchSettings();
}