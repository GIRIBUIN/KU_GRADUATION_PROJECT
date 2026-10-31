import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ku_task_management/data/local/app_database.dart';

void main() {
  group('AppDatabase', () {
    test('opens schema version 7 database', () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);

      expect(database.schemaVersion, 7);

      final row = await database
          .customSelect(
            'SELECT name FROM sqlite_master WHERE type = ? AND name = ?',
            variables: const [Variable('table'), Variable('tasks')],
          )
          .getSingle();

      expect(row.read<String>('name'), 'tasks');
    });

    test('creates core tables', () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);

      final rows = await database
          .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
          .get();
      final tableNames = rows.map((row) => row.read<String>('name')).toSet();

      expect(
        tableNames,
        containsAll({
          'tasks',
          'sub_tasks',
          'tags',
          'task_lists',
          'folder_groups',
          'task_tags',
          'ecampus_items',
          'ecampus_courses',
          'import_sessions',
          'task_reminders',
          'local_notification_schedules',
          'app_settings',
        }),
      );

      final folderColumns = await database
          .customSelect("PRAGMA table_info('task_lists')")
          .get();
      expect(
        folderColumns.map((row) => row.read<String>('name')),
        contains('sort_order'),
      );
    });
  });
}
