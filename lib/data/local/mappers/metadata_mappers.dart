import 'dart:convert';

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
      sortOrder: row.sortOrder,
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
      sortOrder: Value(folder.sortOrder),
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
  static const hiddenTagIdsKey = 'hiddenTagIds';
  static const hiddenFolderIdsKey = 'hiddenFolderIds';
  static const tagFolderIdsKey = 'tagFolderIds';
  static const tagSortOrdersKey = 'tagSortOrders';
  static const ecampusFolderIdKey = 'ecampusFolderId';

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
      hiddenTagIds: _parseStringSet(values[hiddenTagIdsKey]),
      hiddenFolderIds: _parseStringSet(values[hiddenFolderIdsKey]),
      tagFolderIds: _parseStringMap(values[tagFolderIdsKey]),
      tagSortOrders: _parseIntMap(values[tagSortOrdersKey]),
      ecampusFolderId: _emptyToNull(values[ecampusFolderIdKey]),
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
      hiddenTagIdsKey: _encodeStringSet(settings.hiddenTagIds),
      hiddenFolderIdsKey: _encodeStringSet(settings.hiddenFolderIds),
      tagFolderIdsKey: _encodeStringMap(settings.tagFolderIds),
      tagSortOrdersKey: _encodeIntMap(settings.tagSortOrders),
      ecampusFolderIdKey: settings.ecampusFolderId ?? '',
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

  Set<String> _parseStringSet(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return const <String>{};
    }
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is List) {
        return decoded
            .whereType<String>()
            .map((id) => id.trim())
            .where((id) => id.isNotEmpty)
            .toSet();
      }
    } on FormatException {
      return const <String>{};
    }
    return const <String>{};
  }

  String _encodeStringSet(Set<String> ids) {
    final sorted = ids.toList(growable: false)..sort();
    return jsonEncode(sorted);
  }

  Map<String, String> _parseStringMap(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return const <String, String>{};
    }
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map) {
        return decoded.map((key, value) {
          return MapEntry(key.toString(), value.toString());
        })..removeWhere(
          (key, value) => key.trim().isEmpty || value.trim().isEmpty,
        );
      }
    } on FormatException {
      return const <String, String>{};
    }
    return const <String, String>{};
  }

  String _encodeStringMap(Map<String, String> values) {
    final sortedEntries = values.entries.toList(growable: false)
      ..sort((a, b) => a.key.compareTo(b.key));
    return jsonEncode({
      for (final entry in sortedEntries)
        if (entry.key.trim().isNotEmpty && entry.value.trim().isNotEmpty)
          entry.key: entry.value,
    });
  }

  Map<String, int> _parseIntMap(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return const <String, int>{};
    }
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map) {
        final result = <String, int>{};
        for (final entry in decoded.entries) {
          final key = entry.key.toString().trim();
          final value = entry.value;
          final order = value is int ? value : int.tryParse(value.toString());
          if (key.isNotEmpty && order != null) {
            result[key] = order;
          }
        }
        return result;
      }
    } on FormatException {
      return const <String, int>{};
    }
    return const <String, int>{};
  }

  String _encodeIntMap(Map<String, int> values) {
    final sortedEntries = values.entries.toList(growable: false)
      ..sort((a, b) => a.key.compareTo(b.key));
    return jsonEncode({
      for (final entry in sortedEntries)
        if (entry.key.trim().isNotEmpty) entry.key: entry.value,
    });
  }
}
