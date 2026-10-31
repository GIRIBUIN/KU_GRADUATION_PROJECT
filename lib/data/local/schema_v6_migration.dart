part of 'app_database.dart';

extension _V6Migration on AppDatabase {
  Future<void> _migrateV5(Migrator migrator) => transaction(() async {
    const oldTables = [
      'app_settings',
      'notification_settings',
      'task_tags',
      'task_folders',
      'sub_tasks',
      'tasks',
      'tags',
      'folders',
    ];
    // Keep an exact, isolated copy of all legacy rows, including anomalies.
    // No legacy table is dropped during this rollout.
    for (final table in oldTables) {
      await customStatement(
        'ALTER TABLE "$table" RENAME TO "legacy_v5_$table"',
      );
    }
    await migrator.createAll();
    await _ensureInbox();
    Future<List<Map<String, Object?>>> read(String table) async =>
        (await customSelect(
          'SELECT * FROM legacy_v5_$table',
        ).get()).map((r) => r.data).toList();
    final folderRows = await read('folders');
    final tagRows = await read('tags');
    final taskRows = await read('tasks');
    final folderLinks = await read('task_folders');
    final settingRows = await read('app_settings');
    final folderMap = {for (final r in folderRows) r['id'] as String: r};
    final tagIds = tagRows.map((r) => r['id']).toSet();
    final settings = {for (final r in settingRows) r['key']: r['value']};
    Map<String, dynamic> tagOrders = {};
    try {
      final value = jsonDecode(settings['tagSortOrders'] as String? ?? '{}');
      if (value is Map<String, dynamic>) tagOrders = value;
    } catch (_) {
      /* Original value remains in the archive. */
    }

    for (final row in folderRows) {
      final names = <String>[row['name'] as String];
      final seen = <String>{row['id'] as String};
      var parent = row['parent_folder_id'] as String?;
      while (parent != null) {
        if (!seen.add(parent) || !folderMap.containsKey(parent)) {
          await _migrationIssue(
            row['id'] as String,
            'invalid-folder-ancestry',
            row,
          );
          break;
        }
        final ancestor = folderMap[parent]!;
        names.insert(0, ancestor['name'] as String);
        parent = ancestor['parent_folder_id'] as String?;
      }
      await _insertRaw('task_lists', {
        for (final key in [
          'id',
          'color',
          'icon',
          'sort_order',
          'created_at',
          'updated_at',
        ])
          key: row[key],
        'name': names.join(' / '),
      });
    }
    for (final row in tagRows) {
      await _insertRaw('tags', {
        ...row,
        'sort_order': tagOrders[row['id']] is int ? tagOrders[row['id']] : 0,
      });
    }
    final activeTaskIds = <String>{};
    final taskTimes = <String, Object?>{};
    final courses = <String, String>{};
    for (final row in taskRows) {
      final id = row['id'] as String;
      final key = row['ecampus_source_key'] as String?;
      final status = row['status'];
      final ignored = status == 'excluded' && key != null && key.isNotEmpty;
      if (!ignored) {
        final links = folderLinks.where((r) => r['task_id'] == id).toList();
        String? folderId;
        if (links.length == 1 &&
            folderMap.containsKey(links.single['folder_id'])) {
          folderId = links.single['folder_id'] as String;
        } else if (links.isNotEmpty) {
          await _migrationIssue(id, 'ambiguous-or-orphan-task-folder', {
            'links': links,
          });
        }
        final invalidStatus = ![
          'active',
          'completed',
          'deleted',
        ].contains(status);
        if (invalidStatus) {
          await _migrationIssue(id, 'invalid-task-status', row);
        }
        final priority = row['priority'];
        if (priority != null && !['high', 'medium', 'low'].contains(priority)) {
          await _migrationIssue(id, 'invalid-priority', row);
        }
        if (row['parent_task_id'] != null) {
          await _migrationIssue(id, 'legacy-task-parent-reference', row);
        }
        await _insertRaw('tasks', {
          for (final field in [
            'id',
            'title',
            'due_date',
            'memo',
            'sort_order',
            'created_at',
            'updated_at',
          ])
            field: row[field],
          'priority': ['high', 'medium', 'low'].contains(priority)
              ? priority
              : null,
          'list_id': folderId ?? inboxListId,
          'completed_at': status == 'active'
              ? null
              : status == 'completed'
              ? row['completed_at'] ?? row['updated_at']
              : row['completed_at'],
          'deleted_at': status == 'deleted' || invalidStatus
              ? row['deleted_at'] ?? row['updated_at']
              : null,
        });
        activeTaskIds.add(id);
        taskTimes[id] = row['updated_at'];
      }
      if (key != null || row['origin'] == 'ecampus') {
        String? courseId;
        final parts = key?.split(':');
        if (parts != null &&
            parts.length == 3 &&
            parts.every((p) => p.isNotEmpty)) {
          final courseKey = parts.first;
          courseId = courses[courseKey];
          if (courseId == null) {
            courseId = newEntityId();
            courses[courseKey] = courseId;
            await _insertRaw('ecampus_courses', {
              'id': courseId,
              'source_scope_id': AppDatabase.defaultSourceScope,
              'external_course_key': courseKey,
              'name': row['ecampus_source_course'] ?? '',
              'last_observed_at':
                  row['ecampus_last_synced_at'] ?? row['updated_at'],
            });
          }
        } else {
          await _migrationIssue(id, 'unresolved-external-key', row);
        }
        await _insertRaw('ecampus_items', {
          'id': ignored ? id : newEntityId(),
          'source_scope_id': AppDatabase.defaultSourceScope,
          'course_id': courseId,
          'external_key': key,
          'source_title': row['ecampus_source_title'] ?? row['title'],
          'source_course': row['ecampus_source_course'],
          'source_type': row['ecampus_source_type'],
          'source_end_at': row['ecampus_source_due_date'],
          'task_id': ignored ? null : id,
          'import_state': ignored ? 'ignored' : 'imported',
          'first_observed_at': row['created_at'],
          'last_observed_at':
              row['ecampus_last_synced_at'] ?? row['updated_at'],
        });
      }
    }
    final subRows = await read('sub_tasks');
    subRows.sort((a, b) {
      final result = (a['created_at'] as int).compareTo(b['created_at'] as int);
      return result != 0
          ? result
          : (a['id'] as String).compareTo(b['id'] as String);
    });
    final positions = <String, int>{};
    for (final row in subRows) {
      final taskId = row['task_id'] as String;
      if (!activeTaskIds.contains(taskId)) {
        await _migrationIssue(row['id'] as String, 'unlinked-subtask', row);
        continue;
      }
      final position = positions.update(
        taskId,
        (v) => v + 1,
        ifAbsent: () => 0,
      );
      await _insertRaw('sub_tasks', {
        for (final field in [
          'id',
          'task_id',
          'title',
          'created_at',
          'updated_at',
        ])
          field: row[field],
        'position': position,
        'completed_at': row['is_done'] == 1 ? row['updated_at'] : null,
      });
    }
    for (final row in await read('task_tags')) {
      if (!activeTaskIds.contains(row['task_id']) ||
          !tagIds.contains(row['tag_id'])) {
        await _migrationIssue(
          '${row['task_id']}:${row['tag_id']}',
          'unlinked-task-tag',
          row,
        );
        continue;
      }
      await _insertRaw('task_tags', {
        ...row,
        'updated_at': taskTimes[row['task_id']],
      });
    }
    final notifications = await read('notification_settings');
    final notificationGroups = <String, List<Map<String, Object?>>>{};
    for (final row in notifications) {
      notificationGroups
          .putIfAbsent(row['task_id'] as String, () => [])
          .add(row);
    }
    for (final entry in notificationGroups.entries) {
      if (entry.value.length != 1 || !activeTaskIds.contains(entry.key)) {
        await _migrationIssue(entry.key, 'ambiguous-or-unlinked-reminder', {
          'rows': entry.value,
        });
        continue;
      }
      final row = entry.value.single;
      var offset = row['days_before_due'] as int;
      final clock = row['notify_time'] as String;
      if (RegExp(r'^\d{2}:\d{2}$').hasMatch(clock) &&
          offset >= 0 &&
          offset <= 7) {
        offset *= 1440;
      }
      if (offset < 0) {
        await _migrationIssue(entry.key, 'negative-reminder-offset', row);
        continue;
      }
      await _insertRaw('task_reminders', {
        'id': row['id'],
        'task_id': entry.key,
        'enabled': row['enabled'],
        'offset_minutes': offset,
        'updated_at': taskTimes[entry.key],
      });
      await _insertRaw('local_notification_schedules', {
        'task_id': entry.key,
        'scheduled_at': row['scheduled_at'],
      });
    }
    for (final row in settingRows) {
      if (['tagFolderIds', 'tagSortOrders'].contains(row['key'])) continue;
      await _insertRaw('app_settings', row);
    }
    final violations = await customSelect('PRAGMA foreign_key_check').get();
    if (violations.any(
      (r) => !r.read<String>('table').startsWith('legacy_v5_'),
    )) {
      throw StateError('New schema has unresolved foreign key violations');
    }
  });

  Future<void> _insertRaw(String table, Map<String, Object?> values) =>
      customStatement(
        'INSERT INTO "$table" (${values.keys.map((k) => '"$k"').join(',')}) '
        'VALUES (${List.filled(values.length, '?').join(',')})',
        values.values.toList(),
      );

  Future<void> _migrationIssue(
    String entityId,
    String reason,
    Map<String, Object?> data,
  ) => _insertRaw('migration_issues', {
    'entity_id': entityId,
    'reason': reason,
    'legacy_data': jsonEncode(data),
  });
}
