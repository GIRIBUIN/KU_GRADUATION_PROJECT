class AppSettings {
  const AppSettings({
    required this.autoSyncEnabled,
    required this.saveEcampusAccount,
    required this.defaultNotificationEnabled,
    required this.defaultNotificationDays,
    required this.defaultNotificationTime,
    required this.urgentDueDays,
    this.homeSelectedTagId,
    this.hiddenTagIds = const <String>{},
    this.hiddenFolderIds = const <String>{},
    this.tagFolderIds = const <String, String>{},
    this.tagSortOrders = const <String, int>{},
  });

  final bool autoSyncEnabled;
  final bool saveEcampusAccount;
  final bool defaultNotificationEnabled;
  final int defaultNotificationDays;
  final String defaultNotificationTime;
  final int urgentDueDays;
  final String? homeSelectedTagId;
  final Set<String> hiddenTagIds;
  final Set<String> hiddenFolderIds;
  final Map<String, String> tagFolderIds;
  final Map<String, int> tagSortOrders;

  AppSettings copyWith({
    bool? autoSyncEnabled,
    bool? saveEcampusAccount,
    bool? defaultNotificationEnabled,
    int? defaultNotificationDays,
    String? defaultNotificationTime,
    int? urgentDueDays,
    Object? homeSelectedTagId = _appSettingsUnset,
    Set<String>? hiddenTagIds,
    Set<String>? hiddenFolderIds,
    Map<String, String>? tagFolderIds,
    Map<String, int>? tagSortOrders,
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
      hiddenTagIds: hiddenTagIds ?? this.hiddenTagIds,
      hiddenFolderIds: hiddenFolderIds ?? this.hiddenFolderIds,
      tagFolderIds: tagFolderIds ?? this.tagFolderIds,
      tagSortOrders: tagSortOrders ?? this.tagSortOrders,
    );
  }
}

const _appSettingsUnset = Object();

abstract class SettingsRepository {
  Future<AppSettings> getSettings();

  Future<AppSettings> saveSettings(AppSettings settings);
}
