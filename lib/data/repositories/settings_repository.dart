class AppSettings {
  const AppSettings({
    required this.autoSyncEnabled,
    required this.saveEcampusAccount,
    required this.defaultNotificationDays,
  });

  final bool autoSyncEnabled;
  final bool saveEcampusAccount;
  final int defaultNotificationDays;
}

abstract class SettingsRepository {
  Future<AppSettings> getSettings();

  Future<AppSettings> saveSettings(AppSettings settings);
}
