import 'package:drift/drift.dart';

import '../../models/task_models.dart' as models;
import '../../repositories/settings_repository.dart' as settings_model;
import '../app_database.dart' as db;

class TagMapper {
  const TagMapper();

  models.Tag fromRow(db.Tag row) {
    return models.Tag(
      id: row.id,
      name: row.name,
      color: row.color,
      defaultPriority: row.defaultPriority == null
          ? null
          : models.TaskPriority.values.byName(row.defaultPriority!),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  db.TagsCompanion toCompanion(models.Tag tag) {
    return db.TagsCompanion(
      id: Value(tag.id),
      name: Value(tag.name),
      color: Value(tag.color),
      defaultPriority: Value(tag.defaultPriority?.name),
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
      daysBeforeDue: row.daysBeforeDue,
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

  settings_model.AppSettings fromMap(Map<String, String> values) {
    return settings_model.AppSettings(
      autoSyncEnabled: _parseBool(values[autoSyncEnabledKey]) ?? false,
      saveEcampusAccount: _parseBool(values[saveEcampusAccountKey]) ?? false,
      defaultNotificationEnabled:
          _parseBool(values[defaultNotificationEnabledKey]) ?? true,
      defaultNotificationDays:
          int.tryParse(values[defaultNotificationDaysKey] ?? '') ?? 1,
      defaultNotificationTime: values[defaultNotificationTimeKey] ?? '09:00',
      urgentDueDays: int.tryParse(values[urgentDueDaysKey] ?? '') ?? 3,
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
    };
  }

  bool? _parseBool(String? value) {
    return switch (value) {
      'true' => true,
      'false' => false,
      _ => null,
    };
  }
}
