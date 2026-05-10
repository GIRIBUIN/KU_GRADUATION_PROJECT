class AppSettings {
  const AppSettings({
    required this.autoSyncEnabled,
    required this.saveEcampusAccount,
    required this.defaultNotificationEnabled,
    required this.defaultNotificationDays,
    required this.defaultNotificationTime,
    required this.urgentDueDays,
    this.homeSelectedTagId,
  });

  final bool autoSyncEnabled;
  final bool saveEcampusAccount;
  final bool defaultNotificationEnabled;
  final int defaultNotificationDays;
  final String defaultNotificationTime;
  final int urgentDueDays;
  final String? homeSelectedTagId;

  AppSettings copyWith({
    bool? autoSyncEnabled,
    bool? saveEcampusAccount,
    bool? defaultNotificationEnabled,
    int? defaultNotificationDays,
    String? defaultNotificationTime,
    int? urgentDueDays,
    Object? homeSelectedTagId = _appSettingsUnset,
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
      homeSelectedTagId: homeSelectedTagId == _appSettingsUnset
          ? this.homeSelectedTagId
          : homeSelectedTagId as String?,
    );
  }
}

const _appSettingsUnset = Object();

abstract class SettingsRepository {
  Future<AppSettings> getSettings();

  Future<AppSettings> saveSettings(AppSettings settings);
}
