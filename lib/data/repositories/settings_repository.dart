class AppSettings {
  const AppSettings({
    required this.autoSyncEnabled,
    required this.saveEcampusAccount,
    required this.defaultNotificationEnabled,
    required this.defaultNotificationDays,
    required this.defaultNotificationTime,
    required this.urgentDueDays,
  });

  final bool autoSyncEnabled;
  final bool saveEcampusAccount;
  final bool defaultNotificationEnabled;
  final int defaultNotificationDays;
  final String defaultNotificationTime;
  final int urgentDueDays;

  AppSettings copyWith({
    bool? autoSyncEnabled,
    bool? saveEcampusAccount,
    bool? defaultNotificationEnabled,
    int? defaultNotificationDays,
    String? defaultNotificationTime,
    int? urgentDueDays,
  }) {
    return AppSettings(
      autoSyncEnabled: autoSyncEnabled ?? this.autoSyncEnabled,
      saveEcampusAccount: saveEcampusAccount ?? this.saveEcampusAccount,
      defaultNotificationEnabled:
          defaultNotificationEnabled ?? this.defaultNotificationEnabled,
      defaultNotificationDays:
          defaultNotificationDays ?? this.defaultNotificationDays,
      defaultNotificationTime:
          defaultNotificationTime ?? this.defaultNotificationTime,
      urgentDueDays: urgentDueDays ?? this.urgentDueDays,
    );
  }
}

abstract class SettingsRepository {
  Future<AppSettings> getSettings();

  Future<AppSettings> saveSettings(AppSettings settings);
}
