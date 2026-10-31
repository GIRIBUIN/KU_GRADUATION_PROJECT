import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ku_task_management/core/utils/list_defaults.dart';
import 'package:ku_task_management/data/local/app_database.dart' as db;
import 'package:ku_task_management/data/models/task_models.dart';
import 'package:ku_task_management/data/repositories/drift_folder_repository.dart';
import 'package:ku_task_management/data/repositories/drift_task_repository.dart';

final at = DateTime(2026, 10, 30);
Task task(
  String id, {
  String? listId,
  String? sourceKey,
  String course = 'Course',
}) => Task(
  id: id,
  title: id,
  memo: 'Keep memo',
  origin: sourceKey == null ? TaskOrigin.personal : TaskOrigin.ecampus,
  status: TaskStatus.active,
  folderIds: listId == null ? [] : [listId],
  createdAt: at,
  updatedAt: at,
  ecampus: sourceKey == null
      ? null
      : EcampusSyncMetadata(
          sourceKey: sourceKey,
          sourceTitle: id,
          sourceCourse: course,
          sourceType: EcampusTaskType.report,
        ),
);
Folder list(String id, {String? groupId}) =>
    Folder(id: id, name: id, groupId: groupId, createdAt: at, updatedAt: at);

void main() {
  late db.AppDatabase database;
  late DriftTaskRepository tasks;
  late DriftFolderRepository lists;
  setUp(() {
    database = db.AppDatabase(NativeDatabase.memory());
    tasks = DriftTaskRepository(database: database);
    lists = DriftFolderRepository(database: database);
  });
  tearDown(() => database.close());

  test(
    'manual tasks have required Inbox membership; group IDs cannot own tasks',
    () async {
      expect((await lists.getFolders()).single.id, inboxListId);
      final saved = await tasks.createTask(task('manual'));
      expect(saved.listId, inboxListId);
      expect(saved.folderIds, [inboxListId]);
      final columns = await database
          .customSelect('PRAGMA table_info(tasks)')
          .get();
      expect(
        columns.singleWhere((r) => r.data['name'] == 'list_id').data['notnull'],
        1,
      );
      await lists.saveGroup(
        FolderGroup(id: 'school', name: 'School', createdAt: at, updatedAt: at),
      );
      await expectLater(
        tasks.createTask(task('bad', listId: 'school')),
        throwsArgumentError,
      );
      await expectLater(
        database
            .into(database.tasks)
            .insert(
              db.TasksCompanion.insert(
                id: 'raw',
                title: 'raw',
                folderId: const Value('school'),
                createdAt: at,
                updatedAt: at,
              ),
            ),
        throwsA(anything),
      );
      await expectLater(
        database.customStatement('UPDATE tasks SET list_id = NULL'),
        throwsA(anything),
      );
    },
  );

  test(
    'Inbox cannot be archived, renamed or moved, including direct SQL',
    () async {
      await expectLater(lists.deleteFolder(inboxListId), throwsArgumentError);
      await expectLater(
        lists.updateFolder(list(inboxListId)),
        throwsArgumentError,
      );
      await expectLater(
        database.customStatement(
          "UPDATE task_lists SET deleted_at = 1 WHERE id = ?",
          [inboxListId],
        ),
        throwsA(anything),
      );
    },
  );

  test(
    'legacy default list name displays as Unassigned and preserves the fixed identity',
    () async {
      await database.customStatement(
        'UPDATE task_lists SET name = ? WHERE id = ?',
        ['수집함', inboxListId],
      );
      final legacy = (await lists.getFolderById(inboxListId))!;
      expect(legacy.name, inboxListName);
      expect(
        (await database.select(database.folders).get()).single.name,
        '수집함',
      );
      await tasks.createTask(task('manual'));
      await lists.updateFolder(
        Folder(
          id: legacy.id,
          name: legacy.name,
          color: '#EF4444',
          createdAt: legacy.createdAt,
          updatedAt: at,
        ),
      );
      expect((await lists.getFolderById(inboxListId))!.name, '미지정');
      expect((await tasks.getTaskById('manual'))!.listId, inboxListId);
      await expectLater(lists.deleteFolder(inboxListId), throwsArgumentError);
      expect((await lists.getFolders()).single.id, inboxListId);
    },
  );

  test(
    'folder deletion detaches lists without changing any task membership',
    () async {
      await lists.saveGroup(
        FolderGroup(id: 'school', name: 'School', createdAt: at, updatedAt: at),
      );
      await lists.createFolder(list('course', groupId: 'school'));
      await tasks.createTask(task('todo', listId: 'course'));
      await lists.deleteGroup('school');
      expect(await lists.getGroups(), isEmpty);
      expect((await lists.getFolderById('course'))!.groupId, isNull);
      expect((await tasks.getTaskById('todo'))!.listId, 'course');
    },
  );

  test(
    'completion, trash, list archival and restoration preserve original list and completion',
    () async {
      await lists.createFolder(list('course'));
      await tasks.createTask(task('todo', listId: 'course'));
      await tasks.updateTaskStatus('todo', TaskStatus.completed);
      await tasks.markDeleted('todo');
      final before = (await tasks.getTaskById('todo'))!;
      await lists.deleteFolder('course');
      expect((await lists.getFolders()).map((l) => l.id), [inboxListId]);
      expect((await lists.getArchivedLists()).single.id, 'course');
      expect((await tasks.getTaskById('todo'))!.listId, 'course');
      final restored = await tasks.restoreTask('todo');
      expect(restored.listId, 'course');
      expect(restored.status, TaskStatus.completed);
      expect(restored.completedAt, before.completedAt);
      await lists.restoreList('course');
      expect((await lists.getFolderById('course'))!.archivedAt, isNull);
    },
  );

  test('new assignments cannot target archived lists', () async {
    await lists.createFolder(list('old'));
    await lists.deleteFolder('old');
    await expectLater(
      tasks.createTask(task('new', listId: 'old')),
      throwsArgumentError,
    );
    expect(await tasks.getTasks(), isEmpty);
  });

  test(
    'list moves preserve task history and reject stale targets atomically',
    () async {
      for (final id in ['school', 'work']) {
        await lists.saveGroup(
          FolderGroup(id: id, name: id, createdAt: at, updatedAt: at),
        );
      }
      await lists.createFolder(list('course', groupId: 'school'));
      await lists.createFolder(list('target', groupId: 'work'));
      await tasks.createTask(task('todo', listId: 'course'));
      await tasks.updateTaskStatus('todo', TaskStatus.completed);
      await tasks.markDeleted('todo');
      final before = (await tasks.getTaskById('todo'))!;
      await lists.moveList('course', 'work', beforeListId: 'target');
      expect((await lists.getFolderById('course'))!.groupId, 'work');
      expect(
        (await lists.getFolders())
            .where((l) => l.groupId == 'work')
            .map((l) => l.id),
        ['course', 'target'],
      );
      await expectLater(
        lists.moveList('course', 'school', beforeListId: 'target'),
        throwsStateError,
      );
      await expectLater(
        lists.moveList('course', 'missing'),
        throwsArgumentError,
      );
      expect((await lists.getFolderById('course'))!.groupId, 'work');
      await expectLater(
        lists.moveList(inboxListId, 'work'),
        throwsArgumentError,
      );
      await lists.moveList('course', null);
      final after = (await tasks.getTaskById('todo'))!;
      expect(after.listId, before.listId);
      expect(after.status, before.status);
      expect(after.completedAt, before.completedAt);
      expect(after.deletedAt, before.deletedAt);
    },
  );

  test(
    'eCampus creates course lists by source ID, reuses them and preserves manual moves',
    () async {
      final first = await tasks.createTask(
        task('one', sourceKey: 'c1:1:report', course: 'Same name'),
      );
      final second = await tasks.createTask(
        task('two', sourceKey: 'c1:2:quiz', course: 'Same name'),
      );
      final other = await tasks.createTask(
        task('three', sourceKey: 'c2:3:report', course: 'Same name'),
      );
      expect(first.listId, second.listId);
      expect(other.listId, isNot(first.listId));
      expect((await lists.getGroups()).single.id, ecampusFolderId);
      expect(
        (await lists.getFolderById(first.listId))!.groupId,
        ecampusFolderId,
      );
      await tasks.updateTask(
        task(
          'one',
          listId: inboxListId,
          sourceKey: 'c1:1:report',
          course: 'Same name',
        ),
      );
      final replay = await tasks.createTask(
        task('new-id', sourceKey: 'c1:1:report'),
      );
      expect(replay.id, 'one');
      expect(replay.listId, inboxListId);
      final next = await tasks.createTask(
        task('four', sourceKey: 'c1:4:report'),
      );
      expect(next.listId, first.listId);
      expect(
        (await database.select(database.ecampusCourses).get())
            .map((c) => c.listId)
            .toSet(),
        {first.listId, other.listId},
      );
    },
  );

  test(
    'organizing reviewed imports moves only active unassigned tasks and reuses course lists',
    () async {
      await lists.createFolder(list('manual'));
      await tasks.createTask(
        task('one', listId: inboxListId, sourceKey: 'c1:1:report'),
      );
      await tasks.createTask(
        task('two', listId: inboxListId, sourceKey: 'c2:2:report'),
      );
      await tasks.createTask(
        task('done', listId: inboxListId, sourceKey: 'c1:3:report'),
      );
      await tasks.updateTaskStatus('done', TaskStatus.completed);
      await tasks.createTask(
        task('trash', listId: inboxListId, sourceKey: 'c1:4:report'),
      );
      await tasks.markDeleted('trash');
      await tasks.createTask(
        task('moved', listId: 'manual', sourceKey: 'c1:5:report'),
      );
      await tasks.createTask(task('personal', listId: inboxListId));
      final doneBefore = (await tasks.getTaskById('done'))!;
      final trashBefore = (await tasks.getTaskById('trash'))!;
      final selected = ['one', 'two', 'done', 'trash', 'moved', 'personal'];
      final moved = await tasks.organizeUnassignedEcampusTasks(selected);
      expect(moved.map((t) => t.id).toSet(), {'one', 'two'});
      expect(moved.map((t) => t.listId).toSet().length, 2);
      expect((await lists.getGroups()).single.id, ecampusFolderId);
      expect(
        (await tasks.getTaskById('done'))!.completedAt,
        doneBefore.completedAt,
      );
      expect((await tasks.getTaskById('done'))!.listId, inboxListId);
      expect(
        (await tasks.getTaskById('trash'))!.deletedAt,
        trashBefore.deletedAt,
      );
      expect((await tasks.getTaskById('trash'))!.listId, inboxListId);
      expect((await tasks.getTaskById('moved'))!.listId, 'manual');
      expect((await tasks.getTaskById('one'))!.memo, 'Keep memo');
      expect(await tasks.organizeUnassignedEcampusTasks(selected), isEmpty);
      final next = await tasks.createTask(
        task('new', sourceKey: 'c1:6:report'),
      );
      expect(next.listId, (await tasks.getTaskById('one'))!.listId);
      expect((await database.select(database.ecampusItems).get()).length, 6);
    },
  );

  test(
    'organizing imports rolls back moved tasks and created course lists on a later failure',
    () async {
      await tasks.createTask(
        task('a', listId: inboxListId, sourceKey: 'c1:1:report'),
      );
      await tasks.createTask(
        task('b', listId: inboxListId, sourceKey: 'c2:2:report'),
      );
      await database.customStatement(
        "CREATE TRIGGER fail_organize BEFORE UPDATE OF list_id ON tasks WHEN OLD.id='b' BEGIN SELECT RAISE(ABORT,'injected failure'); END",
      );
      await expectLater(
        tasks.organizeUnassignedEcampusTasks(['a', 'b']),
        throwsA(anything),
      );
      expect(
        (await tasks.getTasks()).every((t) => t.listId == inboxListId),
        isTrue,
      );
      expect(await lists.getGroups(), isEmpty);
      expect((await lists.getFolders()).map((l) => l.id), [inboxListId]);
      expect(
        (await database.select(database.ecampusCourses).get()).every(
          (c) => c.listId == null,
        ),
        isTrue,
      );
      expect(
        await database.customSelect('PRAGMA foreign_key_check').get(),
        isEmpty,
      );
    },
  );

  test(
    'archived automatic course list is not silently reopened for new tasks',
    () async {
      final first = await tasks.createTask(
        task('one', sourceKey: 'c:1:report'),
      );
      await lists.deleteFolder(first.listId);
      final second = await tasks.createTask(
        task('two', sourceKey: 'c:2:report'),
      );
      expect(second.listId, isNot(first.listId));
      expect((await tasks.getTaskById('one'))!.listId, first.listId);
      expect((await lists.getFolderById(first.listId))!.archivedAt, isNotNull);
    },
  );

  test(
    'v6 migration preserves all states, source links and child FKs and fills only empty lists',
    () async {
      await database.close();
      final sql = File(
        'test/fixtures/database/schema_v6.sql',
      ).readAsStringSync();
      final migrated = db.AppDatabase(
        NativeDatabase.memory(
          setup: (raw) {
            for (final statement in sql.split(';')) {
              if (statement.trim().isNotEmpty) raw.execute(statement);
            }
            raw.execute(
              "INSERT INTO folders(id,name,created_at,updated_at) VALUES ('old-list','Course',100,200)",
            );
            raw.execute(
              "INSERT INTO tasks(id,title,memo,folder_id,completed_at,deleted_at,created_at,updated_at) VALUES ('active','A','memo','old-list',NULL,NULL,100,200),('completed','B',NULL,'old-list',150,NULL,100,200),('trash','C',NULL,'old-list',150,180,100,200),('unassigned','D',NULL,NULL,NULL,NULL,100,200)",
            );
            raw.execute(
              "INSERT INTO sub_tasks(id,task_id,title,created_at,updated_at) VALUES ('sub','active','Sub',100,200)",
            );
            raw.execute(
              "INSERT INTO tags(id,name,color,created_at,updated_at) VALUES ('tag','Tag','#123456',100,200)",
            );
            raw.execute(
              "INSERT INTO task_tags(task_id,tag_id,updated_at) VALUES ('active','tag',200)",
            );
            raw.execute(
              "INSERT INTO ecampus_courses(id,source_scope_id,external_course_key,name,last_observed_at) VALUES ('course','legacy-local','c','Course',200)",
            );
            raw.execute(
              "INSERT INTO ecampus_items(id,source_scope_id,course_id,external_key,source_title,task_id,import_state,first_observed_at,last_observed_at) VALUES ('source','legacy-local','course','c:1:report','A','active','imported',100,200)",
            );
            raw.execute('PRAGMA foreign_keys = ON');
          },
        ),
      );
      database = migrated;
      final repo = DriftTaskRepository(database: migrated);
      final rows = await repo.getTasks(includeArchived: true);
      expect(rows.map((t) => t.id).toSet(), {
        'active',
        'completed',
        'trash',
        'unassigned',
      });
      expect(rows.singleWhere((t) => t.id == 'unassigned').listId, inboxListId);
      for (final id in ['active', 'completed', 'trash']) {
        expect(rows.singleWhere((t) => t.id == id).listId, 'old-list');
      }
      expect((await repo.getTaskById('active'))!.memo, 'memo');
      expect((await repo.getTaskById('active'))!.tagIds, ['tag']);
      expect(
        (await repo.getTaskById('completed'))!.status,
        TaskStatus.completed,
      );
      expect((await repo.restoreTask('trash')).status, TaskStatus.completed);
      expect(
        (await migrated.select(migrated.ecampusItems).get()).single.taskId,
        'active',
      );
      expect(
        (await migrated.select(migrated.subTasks).get()).single.taskId,
        'active',
      );
      expect(
        await migrated.customSelect('PRAGMA foreign_key_check').get(),
        isEmpty,
      );
      expect(
        (await migrated
                .customSelect('SELECT count(*) AS n FROM legacy_v6_tasks')
                .getSingle())
            .read<int>('n'),
        4,
      );
    },
  );

  test(
    'v6 migration failure rolls back table changes and user_version',
    () async {
      await database.close();
      final sql = File(
        'test/fixtures/database/schema_v6.sql',
      ).readAsStringSync();
      final broken = db.AppDatabase(
        NativeDatabase.memory(
          setup: (raw) {
            for (final statement in sql.split(';')) {
              if (statement.trim().isNotEmpty) raw.execute(statement);
            }
            raw.execute('CREATE TABLE legacy_v6_tasks (id TEXT)');
          },
        ),
      );
      database = broken;
      await expectLater(broken.select(broken.tasks).get(), throwsA(anything));
      final names = await broken.executor.runSelect(
        "SELECT name FROM sqlite_master WHERE type='table'",
        [],
      );
      expect(names.map((r) => r['name']), containsAll(['tasks', 'folders']));
      expect(names.map((r) => r['name']), isNot(contains('task_lists')));
      expect(
        (await broken.executor.runSelect(
          'PRAGMA user_version',
          [],
        )).single.values.single,
        6,
      );
    },
  );
}
