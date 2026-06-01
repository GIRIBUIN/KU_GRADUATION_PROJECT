import 'package:flutter_test/flutter_test.dart';
import 'package:ku_task_management/data/models/ecampus_models.dart';
import 'package:ku_task_management/data/models/task_models.dart';
import 'package:ku_task_management/data/repositories/folder_repository.dart';
import 'package:ku_task_management/data/repositories/settings_repository.dart';
import 'package:ku_task_management/data/repositories/tag_repository.dart';
import 'package:ku_task_management/data/repositories/task_repository.dart';
import 'package:ku_task_management/data/services/ecampus_sync_apply_service.dart';

void main() {
  final syncedAt = DateTime(2026, 5, 7, 12);

  late _FakeTaskRepository repository;
  late _FakeTagRepository tagRepository;
  late _FakeFolderRepository folderRepository;
  late _FakeSettingsRepository settingsRepository;
  late DefaultEcampusSyncApplyService service;

  setUp(() {
    repository = _FakeTaskRepository();
    tagRepository = _FakeTagRepository();
    folderRepository = _FakeFolderRepository();
    settingsRepository = _FakeSettingsRepository();
    service = DefaultEcampusSyncApplyService(
      taskRepository: repository,
      tagRepository: tagRepository,
      folderRepository: folderRepository,
      settingsRepository: settingsRepository,
      now: () => syncedAt,
      createId: (parsedTask, status) =>
          'task-${status.name}-${parsedTask.sourceKey}',
    );
  });

  group('DefaultEcampusSyncApplyService', () {
    test('imports new sync items as active e-campus tasks', () async {
      final applied = await service.importItems([
        SyncItem(kind: SyncItemKind.newItem, parsedTask: _parsedTask()),
      ]);

      expect(applied, hasLength(1));
      expect(applied.single.id, 'task-active-course:item:report');
      expect(applied.single.status, TaskStatus.active);
      expect(applied.single.origin, TaskOrigin.ecampus);
      expect(applied.single.title, '자료구조 과제');
      expect(applied.single.memo, '자료구조');
      expect(applied.single.priority, TaskPriority.medium);
      expect(applied.single.tagIds, [tagRepository.tags.values.single.id]);
      expect(applied.single.folderIds, [
        folderRepository.folders.values.single.id,
      ]);
      expect(applied.single.ecampus?.sourceKey, 'course:item:report');
      expect(applied.single.ecampus?.lastSyncedAt, syncedAt);
      expect(tagRepository.tags.values.single.name, '자료구조');
      expect(tagRepository.tags.values.single.color, '#3B82F6');
      expect(folderRepository.folders.values.single.name, 'e-campus');
      expect(settingsRepository.settings.tagFolderIds, {
        tagRepository.tags.values.single.id:
            folderRepository.folders.values.single.id,
      });
      expect(
        settingsRepository.settings.ecampusFolderId,
        folderRepository.folders.values.single.id,
      );
    });

    test(
      'updates active update candidates and keeps user-owned fields',
      () async {
        final existing = _task(
          id: 'existing',
          sourceKey: 'course:item:report',
          title: '기존 과제',
          tagIds: const ['tag-1'],
          folderIds: const ['folder-1'],
        );
        await repository.createTask(existing);

        final applied = await service.importItems([
          SyncItem(
            kind: SyncItemKind.updateCandidate,
            parsedTask: _parsedTask(title: '변경된 과제'),
            existingTask: existing,
          ),
        ]);

        expect(applied, hasLength(1));
        expect(applied.single.id, 'existing');
        expect(applied.single.title, '변경된 과제');
        expect(applied.single.status, TaskStatus.active);
        expect(applied.single.tagIds, [
          'tag-1',
          tagRepository.tags.values.single.id,
        ]);
        expect(applied.single.folderIds, [
          'folder-1',
          folderRepository.folders.values.single.id,
        ]);
        expect(settingsRepository.settings.tagFolderIds, {
          tagRepository.tags.values.single.id:
              folderRepository.folders.values.single.id,
        });
        expect(
          settingsRepository.settings.ecampusFolderId,
          folderRepository.folders.values.single.id,
        );
        expect(applied.single.createdAt, existing.createdAt);
        expect(applied.single.updatedAt, syncedAt);
      },
    );

    test('reuses saved e-campus folder id after folder is renamed', () async {
      final renamedFolder = await folderRepository.createFolder(
        Folder(
          id: 'folder-ecampus',
          name: '학교',
          color: '#1262D6',
          icon: 'folder',
          createdAt: syncedAt,
          updatedAt: syncedAt,
        ),
      );
      settingsRepository.settings = settingsRepository.settings.copyWith(
        ecampusFolderId: renamedFolder.id,
      );

      final applied = await service.importItems([
        SyncItem(kind: SyncItemKind.newItem, parsedTask: _parsedTask()),
      ]);

      expect(applied.single.folderIds, [renamedFolder.id]);
      expect(folderRepository.folders, hasLength(1));
      expect(settingsRepository.settings.tagFolderIds, {
        tagRepository.tags.values.single.id: renamedFolder.id,
      });
    });

    test(
      'does not update completed, deleted, excluded, or error items',
      () async {
        final completed = _task(
          id: 'completed',
          sourceKey: 'completed',
          status: TaskStatus.completed,
        );

        final applied = await service.importItems([
          SyncItem(
            kind: SyncItemKind.completed,
            parsedTask: _parsedTask(sourceKey: 'completed'),
            existingTask: completed,
          ),
          SyncItem(kind: SyncItemKind.deleted, parsedTask: _parsedTask()),
          SyncItem(kind: SyncItemKind.excluded, parsedTask: _parsedTask()),
          const SyncItem(
            kind: SyncItemKind.error,
            errorMessage: 'parse failed',
          ),
        ]);

        expect(applied, isEmpty);
        expect(repository.tasks, isEmpty);
      },
    );

    test('stores excluded new items as excluded tasks', () async {
      final applied = await service.excludeItems([
        SyncItem(kind: SyncItemKind.newItem, parsedTask: _parsedTask()),
      ]);

      expect(applied, hasLength(1));
      expect(applied.single.id, 'task-excluded-course:item:report');
      expect(applied.single.status, TaskStatus.excluded);
      expect(applied.single.tagIds, isEmpty);
      expect(applied.single.folderIds, isEmpty);
      expect(applied.single.ecampus?.sourceKey, 'course:item:report');
      expect(tagRepository.tags, isEmpty);
      expect(folderRepository.folders, isEmpty);
    });

    test('marks existing active items as excluded', () async {
      final existing = _task(id: 'existing', sourceKey: 'course:item:report');
      await repository.createTask(existing);

      final applied = await service.excludeItems([
        SyncItem(
          kind: SyncItemKind.updateCandidate,
          parsedTask: _parsedTask(title: '제외할 과제'),
          existingTask: existing,
        ),
      ]);

      expect(applied, hasLength(1));
      expect(applied.single.id, 'existing');
      expect(applied.single.status, TaskStatus.excluded);
      expect(applied.single.title, '제외할 과제');
    });

    test('does not exclude completed or deleted existing tasks', () async {
      final completed = _task(
        id: 'completed',
        sourceKey: 'completed',
        status: TaskStatus.completed,
      );
      final deleted = _task(
        id: 'deleted',
        sourceKey: 'deleted',
        status: TaskStatus.deleted,
      );

      final applied = await service.excludeItems([
        SyncItem(
          kind: SyncItemKind.completed,
          parsedTask: _parsedTask(sourceKey: 'completed'),
          existingTask: completed,
        ),
        SyncItem(
          kind: SyncItemKind.deleted,
          parsedTask: _parsedTask(sourceKey: 'deleted'),
          existingTask: deleted,
        ),
      ]);

      expect(applied, isEmpty);
    });
  });
}

ParsedEcampusTask _parsedTask({
  String sourceKey = 'course:item:report',
  String title = '자료구조 과제',
  String course = '자료구조',
  EcampusTaskType type = EcampusTaskType.report,
  DateTime? dueDate,
}) {
  return ParsedEcampusTask(
    sourceKey: sourceKey,
    title: title,
    course: course,
    type: type,
    dueDate: dueDate ?? DateTime(2026, 5, 20),
  );
}

Task _task({
  required String id,
  required String sourceKey,
  String title = '자료구조 과제',
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
    memo: '사용자 메모',
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

class _FakeTaskRepository implements TaskRepository {
  final tasks = <String, Task>{};

  @override
  Future<Task> createTask(Task task) async {
    tasks[task.id] = task;
    return task;
  }

  @override
  Future<Task> updateTask(Task task) async {
    tasks[task.id] = task;
    return task;
  }

  @override
  Future<Task?> getTaskByEcampusSourceKey(String sourceKey) async {
    for (final task in tasks.values) {
      if (task.ecampus?.sourceKey == sourceKey) {
        return task;
      }
    }
    return null;
  }

  @override
  Future<Task?> getTaskById(String id) async => tasks[id];

  @override
  Future<List<Task>> getTasks({
    TaskStatus? status,
    TaskOrigin? origin,
    bool includeArchived = false,
  }) async {
    return tasks.values
        .where((task) {
          if (status != null && task.status != status) {
            return false;
          }
          if (origin != null && task.origin != origin) {
            return false;
          }
          if (!includeArchived && task.isArchived) {
            return false;
          }
          return true;
        })
        .toList(growable: false);
  }

  @override
  Future<Task> updateTaskStatus(String id, TaskStatus status) async {
    final existing = tasks[id];
    if (existing == null) {
      throw StateError('Task not found: $id');
    }

    final updated = Task(
      id: existing.id,
      origin: existing.origin,
      status: status,
      title: existing.title,
      dueDate: existing.dueDate,
      priority: existing.priority,
      memo: existing.memo,
      parentTaskId: existing.parentTaskId,
      tagIds: existing.tagIds,
      folderIds: existing.folderIds,
      ecampus: existing.ecampus,
      sortOrder: existing.sortOrder,
      createdAt: existing.createdAt,
      updatedAt: existing.updatedAt,
      completedAt: existing.completedAt,
      deletedAt: existing.deletedAt,
    );
    tasks[id] = updated;
    return updated;
  }

  @override
  Future<Task> markDeleted(String id) {
    return updateTaskStatus(id, TaskStatus.deleted);
  }

  @override
  Future<Task> restoreTask(String id) {
    return updateTaskStatus(id, TaskStatus.active);
  }

  @override
  Future<void> updateTaskOrder(List<String> orderedTaskIds) async {}

  @override
  Future<void> deletePermanently(String id) async {
    tasks.remove(id);
  }
}

class _FakeTagRepository implements TagRepository {
  final tags = <String, Tag>{};

  @override
  Future<Tag> createTag(Tag tag) async {
    tags[tag.id] = tag;
    return tag;
  }

  @override
  Future<void> deleteTag(String id) async {
    tags.remove(id);
  }

  @override
  Future<Tag?> getTagById(String id) async => tags[id];

  @override
  Future<List<Tag>> getTags() async => tags.values.toList(growable: false);

  @override
  Future<Tag> updateTag(Tag tag) async {
    tags[tag.id] = tag;
    return tag;
  }
}

class _FakeFolderRepository implements FolderRepository {
  final folders = <String, Folder>{};

  @override
  Future<Folder> createFolder(Folder folder) async {
    folders[folder.id] = folder;
    return folder;
  }

  @override
  Future<void> deleteFolder(String id) async {
    folders.remove(id);
  }

  @override
  Future<Folder?> getFolderById(String id) async => folders[id];

  @override
  Future<List<Folder>> getFolders() async =>
      folders.values.toList(growable: false);

  @override
  Future<Folder> updateFolder(Folder folder) async {
    folders[folder.id] = folder;
    return folder;
  }

  @override
  Future<void> updateFolderOrder(List<String> folderIds) async {}
}

class _FakeSettingsRepository implements SettingsRepository {
  AppSettings settings = const AppSettings(
    autoSyncEnabled: false,
    saveEcampusAccount: false,
    defaultNotificationEnabled: true,
    defaultNotificationDays: 60,
    defaultNotificationTime: 'relative',
    urgentDueDays: 3,
  );

  @override
  Future<AppSettings> getSettings() async => settings;

  @override
  Future<AppSettings> saveSettings(AppSettings settings) async {
    this.settings = settings;
    return settings;
  }
}
