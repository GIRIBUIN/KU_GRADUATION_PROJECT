import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ku_task_management/data/local/app_database.dart' as db;
import 'package:ku_task_management/data/models/ecampus_models.dart';
import 'package:ku_task_management/data/models/task_models.dart';
import 'package:ku_task_management/data/repositories/drift_folder_repository.dart';
import 'package:ku_task_management/data/repositories/drift_notification_repository.dart';
import 'package:ku_task_management/data/repositories/drift_settings_repository.dart';
import 'package:ku_task_management/data/repositories/drift_tag_repository.dart';
import 'package:ku_task_management/data/repositories/drift_task_repository.dart';
import 'package:ku_task_management/data/services/ecampus_sync_apply_service.dart';

final _at = DateTime.utc(2026, 10, 30, 1);
Task _task(
  String id, {
  TaskStatus status = TaskStatus.active,
  List<String> folders = const [],
  List<String> tags = const [],
  EcampusSyncMetadata? source,
}) => Task(
  id: id,
  origin: source == null ? TaskOrigin.personal : TaskOrigin.ecampus,
  status: status,
  title: 'User title',
  memo: 'Keep my memo',
  folderIds: folders,
  tagIds: tags,
  ecampus: source,
  createdAt: _at,
  updatedAt: _at,
);
DefaultEcampusSyncApplyService _apply(
  db.AppDatabase database, {
  String Function(ParsedEcampusTask, TaskStatus)? createId,
}) => DefaultEcampusSyncApplyService(
  taskRepository: DriftTaskRepository(database: database),
  folderRepository: DriftFolderRepository(database: database),
  tagRepository: DriftTagRepository(database: database),
  settingsRepository: DriftSettingsRepository(database: database),
  createId: createId,
);
SyncItem _new(String key) => SyncItem(
  kind: SyncItemKind.newItem,
  parsedTask: ParsedEcampusTask(
    sourceKey: key,
    title: key,
    course: 'Course',
    type: EcampusTaskType.report,
  ),
);

void main() {
  test(
    'migration reports ambiguous legacy data without discarding the original rows',
    () async {
      final sql = File(
        'test/fixtures/database/schema_v5.sql',
      ).readAsStringSync();
      final database = db.AppDatabase(
        NativeDatabase.memory(
          setup: (raw) {
            for (final statement in sql.split(';')) {
              if (statement.trim().isNotEmpty) {
                raw.execute(statement);
              }
            }
            raw.execute(
              "INSERT INTO folders VALUES ('a','A',NULL,NULL,NULL,0,1000,1000),('b','B',NULL,NULL,NULL,0,1000,1000)",
            );
            raw.execute(
              "INSERT INTO tasks(id,origin,status,title,created_at,updated_at,ecampus_source_key) VALUES ('task','ecampus','active','Keep',1000,2000,'unresolved-key')",
            );
            raw.execute(
              "INSERT INTO task_folders VALUES ('task','a'),('task','b')",
            );
            raw.execute("INSERT INTO task_tags VALUES ('task','missing-tag')");
            raw.execute(
              "INSERT INTO notification_settings VALUES ('one','task',1,30,'relative',NULL),('two','task',1,60,'relative',NULL)",
            );
          },
        ),
      );
      addTearDown(database.close);
      final task = (await DriftTaskRepository(
        database: database,
      ).getTaskById('task'))!;
      expect(task.title, 'Keep');
      expect(task.folderIds, isEmpty);
      expect(task.ecampus!.sourceKey, 'unresolved-key');
      final reasons = (await database.select(database.migrationIssues).get())
          .map((r) => r.reason);
      expect(
        reasons,
        containsAll([
          'ambiguous-or-orphan-task-folder',
          'unresolved-external-key',
          'unlinked-task-tag',
          'ambiguous-or-unlinked-reminder',
        ]),
      );
      expect(
        (await database
                .customSelect(
                  'SELECT COUNT(*) AS n FROM legacy_v5_task_folders',
                )
                .getSingle())
            .read<int>('n'),
        2,
      );
      expect(
        (await database
                .customSelect(
                  'SELECT COUNT(*) AS n FROM legacy_v5_notification_settings',
                )
                .getSingle())
            .read<int>('n'),
        2,
      );
      expect(await database.select(database.taskReminders).get(), isEmpty);
    },
  );

  test(
    'local notification IDs remain unique and scheduling state stays separate',
    () async {
      final database = db.AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final tasks = DriftTaskRepository(database: database);
      await tasks.createTask(_task('one'));
      await tasks.createTask(_task('two'));
      final notifications = DriftNotificationRepository(database: database);
      expect(await notifications.notificationId('one', 123), 123);
      expect(await notifications.notificationId('two', 123), 124);
      expect(await notifications.notificationId('one', 123), 123);
      await notifications.recordSchedule('one', _at);
      final local = await (database.select(
        database.localNotificationSchedules,
      )..where((t) => t.taskId.equals('one'))).getSingle();
      expect(local.scheduledAt!.isAtSameMomentAs(_at), isTrue);
      expect(await database.select(database.taskReminders).get(), isEmpty);
    },
  );

  test(
    'fresh v6 enforces FK and separates state, source and reminder data',
    () async {
      final database = db.AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      expect(database.schemaVersion, 6);
      expect(
        (await database.customSelect('PRAGMA foreign_keys').getSingle())
            .data
            .values
            .single,
        1,
      );
      final columns =
          (await database.customSelect('PRAGMA table_info(tasks)').get())
              .map((r) => r.read<String>('name'))
              .toSet();
      expect(columns, containsAll(['folder_id', 'completed_at', 'deleted_at']));
      expect(
        columns.intersection({
          'origin',
          'status',
          'parent_task_id',
          'ecampus_source_key',
        }),
        isEmpty,
      );
      final repo = DriftTaskRepository(database: database);
      await expectLater(
        repo.createTask(_task('orphan', folders: ['not-a-folder'])),
        throwsA(anything),
      );
      expect(await database.select(database.tasks).get(), isEmpty);
    },
  );

  test(
    'single folder, global tags, reopen and restore keep coherent state',
    () async {
      final database = db.AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final folders = DriftFolderRepository(database: database);
      for (final id in ['a', 'b']) {
        await folders.createFolder(
          Folder(id: id, name: id, createdAt: _at, updatedAt: _at),
        );
      }
      final tags = DriftTagRepository(database: database);
      await tags.createTag(
        Tag(
          id: 'tag',
          name: 'Shared',
          color: '#123456',
          createdAt: _at,
          updatedAt: _at,
        ),
      );
      final repo = DriftTaskRepository(database: database, now: () => _at);
      await expectLater(
        repo.createTask(_task('bad', folders: ['a', 'b'])),
        throwsArgumentError,
      );
      await repo.createTask(_task('a-task', folders: ['a'], tags: ['tag']));
      await repo.createTask(_task('b-task', folders: ['b'], tags: ['tag']));
      await repo.updateTaskStatus('a-task', TaskStatus.completed);
      expect(
        (await repo.updateTaskStatus('a-task', TaskStatus.active)).completedAt,
        isNull,
      );
      await repo.updateTaskStatus('a-task', TaskStatus.completed);
      await repo.markDeleted('a-task');
      expect((await repo.restoreTask('a-task')).status, TaskStatus.completed);
      await folders.deleteFolder('a');
      expect((await repo.getTaskById('a-task'))!.folderIds, isEmpty);
      expect((await repo.getTaskById('b-task'))!.tagIds, ['tag']);
      expect(await tags.getTags(), hasLength(1));
      await tags.deleteTag('tag');
      expect((await repo.getTaskById('b-task'))!.tagIds, isEmpty);
    },
  );

  test(
    'import is atomic when a later selected item cannot be stored',
    () async {
      final database = db.AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final service = _apply(database, createId: (_, _) => 'same-id');
      await expectLater(
        service.importItems([_new('c:1:report'), _new('c:2:report')]),
        throwsA(anything),
      );
      expect(await database.select(database.tasks).get(), isEmpty);
      expect(await database.select(database.ecampusItems).get(), isEmpty);
      expect(await database.select(database.ecampusCourses).get(), isEmpty);
      expect(await database.select(database.importSessions).get(), isEmpty);
    },
  );

  test(
    'source updates preserve memo and repeated import does not duplicate',
    () async {
      final database = db.AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final service = _apply(database);
      final first = (await service.importItems([_new('c:1:report')])).single;
      final repo = DriftTaskRepository(database: database);
      final original = await repo.updateTask(
        Task(
          id: first.id,
          origin: first.origin,
          status: first.status,
          title: first.title,
          memo: 'User memo',
          ecampus: first.ecampus,
          createdAt: first.createdAt,
          updatedAt: first.updatedAt,
        ),
      );
      final changed = SyncItem(
        kind: SyncItemKind.updateCandidate,
        existingTask: original,
        parsedTask: const ParsedEcampusTask(
          sourceKey: 'c:1:report',
          title: 'New source title',
          course: 'Course',
          type: EcampusTaskType.report,
        ),
      );
      expect((await service.importItems([changed])).single.memo, 'User memo');
      await service.importItems([_new('c:1:report')]);
      expect(await database.select(database.tasks).get(), hasLength(1));
      expect(await database.select(database.ecampusItems).get(), hasLength(1));
      final ignored = (await service.excludeItems([_new('c:2:report')])).single;
      expect(ignored.status, TaskStatus.excluded);
      expect(await database.select(database.tasks).get(), hasLength(1));
      await repo.deletePermanently(ignored.id);
      expect(await repo.getTaskByEcampusSourceKey('c:2:report'), isNull);
      await service.importItems([_new('c:2:report')]);
      expect(await database.select(database.tasks).get(), hasLength(2));
    },
  );

  test(
    'reminders are unique per task and negative offsets are rejected',
    () async {
      final database = db.AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      await DriftTaskRepository(database: database).createTask(_task('task'));
      final repo = DriftNotificationRepository(database: database);
      for (final id in ['r1', 'r2']) {
        await repo.save(
          NotificationSetting(
            id: id,
            taskId: 'task',
            enabled: true,
            daysBeforeDue: 30,
            notifyTime: 'relative',
          ),
        );
      }
      expect(await database.select(database.taskReminders).get(), hasLength(1));
      await expectLater(
        database
            .into(database.taskReminders)
            .insert(
              db.TaskRemindersCompanion.insert(
                id: 'other',
                taskId: 'task',
                enabled: true,
                offsetMinutes: 10,
                updatedAt: _at,
              ),
            ),
        throwsA(anything),
      );
      await expectLater(
        repo.save(
          const NotificationSetting(
            id: 'bad',
            taskId: 'task',
            enabled: true,
            daysBeforeDue: -1,
            notifyTime: 'relative',
          ),
        ),
        throwsArgumentError,
      );
    },
  );

  test(
    'v5 migration preserves IDs and data, flattens folders and archives all rows',
    () async {
      final root = Directory('build/db-v6')..createSync(recursive: true);
      final dir = root.createTempSync('migration-');
      addTearDown(() {
        if (dir.absolute.path.startsWith(root.absolute.path)) {
          dir.deleteSync(recursive: true);
        }
      });
      final file = File('${dir.path}/legacy.sqlite');
      final sql = File(
        'test/fixtures/database/schema_v5.sql',
      ).readAsStringSync();
      final database = db.AppDatabase(
        NativeDatabase(
          file,
          setup: (raw) {
            for (final statement in sql.split(';')) {
              if (statement.trim().isNotEmpty) raw.execute(statement);
            }
            raw.execute(
              "INSERT INTO folders VALUES ('root','Root',NULL,NULL,NULL,0,1000,1000),('child','Child',NULL,NULL,'root',1,1000,1000)",
            );
            raw.execute(
              "INSERT INTO tags VALUES ('tag','Course','#123456',1000,1000)",
            );
            raw.execute(
              "INSERT INTO tasks(id,origin,status,title,memo,created_at,updated_at,completed_at,ecampus_source_key,ecampus_source_title,ecampus_source_due_date,ecampus_source_course,ecampus_source_type) VALUES ('task','ecampus','active','User title','User memo',1000,2000,1500,'c:1:report','Source title',3000,'Course','report'),('ignored','ecampus','excluded','Ignored',NULL,1000,2000,NULL,'c:2:report','Ignored',4000,'Course','report')",
            );
            raw.execute("INSERT INTO task_folders VALUES ('task','child')");
            raw.execute("INSERT INTO task_tags VALUES ('task','tag')");
            raw.execute(
              "INSERT INTO sub_tasks VALUES ('sub','task','Child task',1,1000,2000)",
            );
            raw.execute(
              "INSERT INTO notification_settings VALUES ('reminder','task',1,2,'09:00',2500)",
            );
            raw.execute(
              "INSERT INTO app_settings VALUES ('tagFolderIds','{\"tag\":\"child\"}',2000),('tagSortOrders','{\"tag\":4}',2000)",
            );
          },
        ),
      );
      final repo = DriftTaskRepository(database: database);
      final task = await repo.getTaskById('task');
      expect(task!.id, 'task');
      expect(task.memo, 'User memo');
      expect(task.completedAt, isNull);
      expect(task.folderIds, ['child']);
      expect(task.tagIds, ['tag']);
      expect(task.ecampus!.sourceTitle, 'Source title');
      expect((await database.select(database.tasks).get()).map((r) => r.id), [
        'task',
      ]);
      expect(
        (await foldersFor(database)).map((r) => r.name),
        contains('Root / Child'),
      );
      expect(
        (await database.select(database.subTasks).get()).single.position,
        0,
      );
      expect(
        (await database.select(database.taskReminders).get())
            .single
            .offsetMinutes,
        2880,
      );
      expect((await database.select(database.tags).get()).single.sortOrder, 4);
      expect(
        (await DriftSettingsRepository(
          database: database,
        ).getSettings()).tagFolderIds,
        isEmpty,
      );
      expect(
        (await repo.getTasks(status: TaskStatus.excluded)).single.id,
        'ignored',
      );
      expect(
        (await database
                .customSelect('SELECT COUNT(*) AS n FROM legacy_v5_tasks')
                .getSingle())
            .read<int>('n'),
        2,
      );
      expect(
        await database.customSelect('PRAGMA foreign_key_check').get(),
        isEmpty,
      );
      final sourceIds = (await database.select(database.ecampusItems).get())
          .map((r) => r.id)
          .toSet();
      await database.close();
      final reopened = db.AppDatabase(NativeDatabase(file));
      addTearDown(reopened.close);
      expect(
        (await reopened.select(reopened.ecampusItems).get())
            .map((r) => r.id)
            .toSet(),
        sourceIds,
      );
    },
  );

  test(
    'migration failure rolls table renames back instead of damaging v5',
    () async {
      final sql = File(
        'test/fixtures/database/schema_v5.sql',
      ).readAsStringSync();
      final database = db.AppDatabase(
        NativeDatabase.memory(
          setup: (raw) {
            for (final statement in sql.split(';')) {
              if (statement.trim().isNotEmpty) raw.execute(statement);
            }
            raw.execute('CREATE TABLE legacy_v5_tags (id TEXT)');
          },
        ),
      );
      await expectLater(
        database.select(database.tasks).get(),
        throwsA(anything),
      );
      // Use the underlying executor, avoiding a second generated ensureOpen call.
      final rows = await database.executor.runSelect(
        "SELECT name FROM sqlite_master WHERE type='table'",
        [],
      );
      expect(
        rows.map((r) => r['name']),
        containsAll(['tasks', 'folders', 'tags', 'notification_settings']),
      );
      expect(
        (await database.executor.runSelect(
          'PRAGMA user_version',
          [],
        )).single.values.single,
        5,
      );
      await database.close();
    },
  );
}

Future<List<db.Folder>> foldersFor(db.AppDatabase database) =>
    database.select(database.folders).get();
