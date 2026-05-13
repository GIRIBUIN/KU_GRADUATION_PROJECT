import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ku_task_management/data/local/app_database.dart'
    show AppDatabase, FoldersCompanion, TagsCompanion;
import 'package:ku_task_management/data/models/task_models.dart';
import 'package:ku_task_management/data/repositories/drift_task_repository.dart';

void main() {
  late AppDatabase database;
  late DriftTaskRepository repository;

  final now = DateTime(2026, 5, 7, 10);

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    repository = DriftTaskRepository(database: database, now: () => now);

    await database
        .into(database.tags)
        .insert(
          TagsCompanion.insert(
            id: 'tag-1',
            name: '전공',
            color: '#1262D6',
            createdAt: now,
            updatedAt: now,
          ),
        );
    await database
        .into(database.folders)
        .insert(
          FoldersCompanion.insert(
            id: 'folder-1',
            name: '이번 주',
            createdAt: now,
            updatedAt: now,
          ),
        );
  });

  tearDown(() async {
    await database.close();
  });

  group('DriftTaskRepository', () {
    test(
      'creates and reads a task with e-campus metadata and relations',
      () async {
        final task = _task(
          id: 'task-1',
          tagIds: const ['tag-1'],
          folderIds: const ['folder-1'],
        );

        await repository.createTask(task);

        final saved = await repository.getTaskById('task-1');

        expect(saved, isNotNull);
        expect(saved!.title, '자료구조 과제');
        expect(saved.origin, TaskOrigin.ecampus);
        expect(saved.status, TaskStatus.active);
        expect(saved.tagIds, ['tag-1']);
        expect(saved.folderIds, ['folder-1']);
        expect(saved.ecampus?.sourceKey, 'course:item:report');
      },
    );

    test('finds a task by e-campus sourceKey', () async {
      await repository.createTask(_task(id: 'task-1'));

      final saved = await repository.getTaskByEcampusSourceKey(
        'course:item:report',
      );

      expect(saved?.id, 'task-1');
    });

    test(
      'filters active tasks by default and can include archived tasks',
      () async {
        await repository.createTask(_task(id: 'active'));
        await repository.createTask(
          _task(
            id: 'completed',
            sourceKey: 'course:item:completed',
            status: TaskStatus.completed,
          ),
        );

        final activeTasks = await repository.getTasks();
        final allTasks = await repository.getTasks(includeArchived: true);
        final completedTasks = await repository.getTasks(
          status: TaskStatus.completed,
        );

        expect(activeTasks.map((task) => task.id), ['active']);
        expect(allTasks.map((task) => task.id).toSet(), {
          'active',
          'completed',
        });
        expect(completedTasks.map((task) => task.id), ['completed']);
      },
    );

    test('updates task fields and relations', () async {
      await repository.createTask(_task(id: 'task-1'));

      final updated = await repository.updateTask(
        _task(
          id: 'task-1',
          title: '수정된 과제',
          tagIds: const ['tag-1'],
          folderIds: const ['folder-1'],
        ),
      );

      expect(updated.title, '수정된 과제');
      expect(updated.tagIds, ['tag-1']);
      expect(updated.folderIds, ['folder-1']);
    });

    test('updates status and marks completed/deleted timestamps', () async {
      await repository.createTask(_task(id: 'task-1'));

      final completed = await repository.updateTaskStatus(
        'task-1',
        TaskStatus.completed,
      );
      final deleted = await repository.markDeleted('task-1');

      expect(completed.status, TaskStatus.completed);
      expect(completed.completedAt, now);
      expect(deleted.status, TaskStatus.deleted);
      expect(deleted.deletedAt, now);
    });

    test('restores a task to active status', () async {
      await repository.createTask(
        _task(id: 'task-1', status: TaskStatus.deleted),
      );

      final restored = await repository.restoreTask('task-1');

      expect(restored.status, TaskStatus.active);
      expect(restored.completedAt, isNull);
      expect(restored.deletedAt, isNull);
    });

    test('deletes a task permanently', () async {
      await repository.createTask(
        _task(
          id: 'task-1',
          tagIds: const ['tag-1'],
          folderIds: const ['folder-1'],
        ),
      );

      await repository.deletePermanently('task-1');

      expect(await repository.getTaskById('task-1'), isNull);
      expect(await database.select(database.taskTags).get(), isEmpty);
      expect(await database.select(database.taskFolders).get(), isEmpty);
    });

    test('creates tasks at the end and updates user order', () async {
      await repository.createTask(
        _task(id: 'task-1', sourceKey: 'course:item:1'),
      );
      await repository.createTask(
        _task(id: 'task-2', sourceKey: 'course:item:2'),
      );
      await repository.createTask(
        _task(id: 'task-3', sourceKey: 'course:item:3'),
      );

      expect((await repository.getTasks()).map((task) => task.id), [
        'task-1',
        'task-2',
        'task-3',
      ]);

      await repository.updateTaskOrder(['task-3', 'task-1', 'task-2']);

      expect((await repository.getTasks()).map((task) => task.id), [
        'task-3',
        'task-1',
        'task-2',
      ]);
    });
  });
}

Task _task({
  required String id,
  String title = '자료구조 과제',
  String sourceKey = 'course:item:report',
  TaskStatus status = TaskStatus.active,
  List<String> tagIds = const [],
  List<String> folderIds = const [],
}) {
  final now = DateTime(2026, 5, 7, 9);

  return Task(
    id: id,
    origin: TaskOrigin.ecampus,
    status: status,
    title: title,
    dueDate: DateTime(2026, 5, 20),
    priority: TaskPriority.high,
    memo: '메모',
    tagIds: tagIds,
    folderIds: folderIds,
    ecampus: EcampusSyncMetadata(
      sourceKey: sourceKey,
      sourceTitle: title,
      sourceDueDate: DateTime(2026, 5, 20),
      sourceCourse: '자료구조',
      sourceType: EcampusTaskType.report,
      lastSyncedAt: now,
    ),
    createdAt: now,
    updatedAt: now,
    completedAt: status == TaskStatus.completed ? now : null,
    deletedAt: status == TaskStatus.deleted ? now : null,
  );
}
