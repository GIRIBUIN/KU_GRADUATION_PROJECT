import 'package:drift/drift.dart';

import '../../models/task_models.dart' as models;
import '../../repositories/settings_repository.dart' as settings_model;
import '../app_database.dart' as db;

int _normalizeNotificationOffsetMinutes(int? value, String? notifyTime) {
  if (value == null) {
    return 60;
  }
  if (notifyTime == null || notifyTime == 'relative') {
    return value;
  }
  if (RegExp(r'^\d{2}:\d{2}$').hasMatch(notifyTime.trim()) &&
      value >= 0 &&
      value <= 7) {
    return value * 24 * 60;
  }
  return value;
}

class TagMapper {
  const TagMapper();

  models.Tag fromRow(db.Tag row) {
    return models.Tag(
      id: row.id,
      name: row.name,
      color: row.color,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  db.TagsCompanion toCompanion(models.Tag tag) {
    return db.TagsCompanion(
      id: Value(tag.id),
      name: Value(tag.name),
      color: Value(tag.color),
      createdAt: Value(tag.createdAt),
      updatedAt: Value(tag.updatedAt),
    );
  }
}

class FolderMapper {
  const FolderMapper();

  models.Folder fromRow(db.Folder row) {
    return models.Folder(
      id: row.id,
      name: row.name,
      color: row.color,
      icon: row.icon,
      parentFolderId: row.parentFolderId,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  db.FoldersCompanion toCompanion(models.Folder folder) {
    return db.FoldersCompanion(
      id: Value(folder.id),
      name: Value(folder.name),
      color: Value(folder.color),
      icon: Value(folder.icon),
      parentFolderId: Value(folder.parentFolderId),
      createdAt: Value(folder.createdAt),
      updatedAt: Value(folder.updatedAt),
    );
  }
}

class NotificationSettingMapper {
  const NotificationSettingMapper();

  models.NotificationSetting fromRow(db.NotificationSetting row) {
    return models.NotificationSetting(
      id: row.id,
      taskId: row.taskId,
      enabled: row.enabled,
      daysBeforeDue: _normalizeNotificationOffsetMinutes(
        row.daysBeforeDue,
        row.notifyTime,
      ),
      notifyTime: row.notifyTime,
      scheduledAt: row.scheduledAt,
    );
  }

  db.NotificationSettingsCompanion toCompanion(
    models.NotificationSetting notification,
  ) {
    return db.NotificationSettingsCompanion(
      id: Value(notification.id),
      taskId: Value(notification.taskId),
      enabled: Value(notification.enabled),
      daysBeforeDue: Value(notification.daysBeforeDue),
      notifyTime: Value(notification.notifyTime),
      scheduledAt: Value(notification.scheduledAt),
    );
  }
}

class AppSettingsMapper {
  const AppSettingsMapper();

  static const autoSyncEnabledKey = 'autoSyncEnabled';
  static const saveEcampusAccountKey = 'saveEcampusAccount';
  static const defaultNotificationEnabledKey = 'defaultNotificationEnabled';
  static const defaultNotificationDaysKey = 'defaultNotificationDays';
  static const defaultNotificationTimeKey = 'defaultNotificationTime';
  static const urgentDueDaysKey = 'urgentDueDays';
  static const homeSelectedTagIdKey = 'homeSelectedTagId';

  settings_model.AppSettings fromMap(Map<String, String> values) {
    return settings_model.AppSettings(
      autoSyncEnabled: _parseBool(values[autoSyncEnabledKey]) ?? false,
      saveEcampusAccount: _parseBool(values[saveEcampusAccountKey]) ?? false,
      defaultNotificationEnabled:
          _parseBool(values[defaultNotificationEnabledKey]) ?? true,
      defaultNotificationDays: _normalizeNotificationOffsetMinutes(
        int.tryParse(values[defaultNotificationDaysKey] ?? ''),
        values[defaultNotificationTimeKey],
      ),
      defaultNotificationTime: values[defaultNotificationTimeKey] ?? 'relative',
      urgentDueDays: int.tryParse(values[urgentDueDaysKey] ?? '') ?? 3,
      homeSelectedTagId: _emptyToNull(values[homeSelectedTagIdKey]),
    );
  }

  Map<String, String> toMap(settings_model.AppSettings settings) {
    return {
      autoSyncEnabledKey: settings.autoSyncEnabled.toString(),
      saveEcampusAccountKey: settings.saveEcampusAccount.toString(),
      defaultNotificationEnabledKey: settings.defaultNotificationEnabled
          .toString(),
      defaultNotificationDaysKey: settings.defaultNotificationDays.toString(),
      defaultNotificationTimeKey: settings.defaultNotificationTime,
      urgentDueDaysKey: settings.urgentDueDays.toString(),
      homeSelectedTagIdKey: settings.homeSelectedTagId ?? '',
    };
  }

  bool? _parseBool(String? value) {
    return switch (value) {
      'true' => true,
      'false' => false,
      _ => null,
    };
  }

  String? _emptyToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
