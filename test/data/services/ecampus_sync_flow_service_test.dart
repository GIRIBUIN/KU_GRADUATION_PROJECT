import 'package:flutter_test/flutter_test.dart';
import 'package:ku_task_management/data/models/ecampus_models.dart';
import 'package:ku_task_management/data/models/task_models.dart';
import 'package:ku_task_management/data/repositories/task_repository.dart';
import 'package:ku_task_management/data/services/ecampus_auth_service.dart';
import 'package:ku_task_management/data/services/ecampus_sync_apply_service.dart';
import 'package:ku_task_management/data/services/ecampus_sync_flow_service.dart';
import 'package:ku_task_management/data/services/ecampus_sync_service.dart';

void main() {
  final session = EcampusSession(
    cookies: const {'JSESSIONID': 'session-id'},
    createdAt: DateTime(2026, 5, 7, 10),
  );
  final syncedAt = DateTime(2026, 5, 7, 12);

  late _FakeTaskRepository taskRepository;
  late _FakeEcampusSyncService syncService;
  late _FakeEcampusSyncApplyService applyService;
  late DefaultEcampusSyncFlowService flowService;

  setUp(() {
    taskRepository = _FakeTaskRepository();
    syncService = _FakeEcampusSyncService(syncedAt: syncedAt);
    applyService = _FakeEcampusSyncApplyService();
    flowService = DefaultEcampusSyncFlowService(
      taskRepository: taskRepository,
      syncService: syncService,
      applyService: applyService,
    );
  });

  group('DefaultEcampusSyncFlowService', () {
    test('previews sync with all archived e-campus tasks included', () async {
      final activeTask = _task(id: 'active', status: TaskStatus.active);
      final completedTask = _task(
        id: 'completed',
        status: TaskStatus.completed,
      );
      final personalTask = _task(
        id: 'personal',
        origin: TaskOrigin.personal,
        status: TaskStatus.active,
      );
      taskRepository.tasks.addAll([activeTask, completedTask, personalTask]);

      final result = await flowService.preview(
        session: session,
        syncedAt: syncedAt,
      );

      expect(result.syncedAt, syncedAt);
      expect(taskRepository.lastOrigin, TaskOrigin.ecampus);
      expect(taskRepository.lastIncludeArchived, isTrue);
      expect(syncService.lastSession, session);
      expect(syncService.lastSyncedAt, syncedAt);
      expect(syncService.lastExistingTasks, [activeTask, completedTask]);
    });

    test('delegates selected import items to apply service', () async {
      final items = [
        SyncItem(kind: SyncItemKind.newItem, parsedTask: _parsedTask()),
      ];

      final imported = await flowService.importItems(items, syncedAt: syncedAt);

      expect(imported, applyService.importResult);
      expect(applyService.lastImportItems, items);
      expect(applyService.lastImportSyncedAt, syncedAt);
    });

    test('delegates selected exclude items to apply service', () async {
      final items = [
        SyncItem(kind: SyncItemKind.newItem, parsedTask: _parsedTask()),
      ];

      final excluded = await flowService.excludeItems(
        items,
        syncedAt: syncedAt,
      );

      expect(excluded, applyService.excludeResult);
      expect(applyService.lastExcludeItems, items);
      expect(applyService.lastExcludeSyncedAt, syncedAt);
    });
  });
}

ParsedEcampusTask _parsedTask() {
  return const ParsedEcampusTask(
    sourceKey: 'course:item:report',
    title: '자료구조 과제',
    course: '자료구조',
    type: EcampusTaskType.report,
  );
}

Task _task({
  required String id,
  TaskOrigin origin = TaskOrigin.ecampus,
  TaskStatus status = TaskStatus.active,
}) {
  final now = DateTime(2026, 5, 7, 9);

  return Task(
    id: id,
    origin: origin,
    status: status,
    title: '자료구조 과제',
    createdAt: now,
    updatedAt: now,
    ecampus: origin == TaskOrigin.ecampus
        ? EcampusSyncMetadata(
            sourceKey: 'source-$id',
            sourceTitle: '자료구조 과제',
            lastSyncedAt: now,
          )
        : null,
  );
}

class _FakeTaskRepository implements TaskRepository {
  final tasks = <Task>[];

  TaskStatus? lastStatus;
  TaskOrigin? lastOrigin;
  bool? lastIncludeArchived;

  @override
  Future<List<Task>> getTasks({
    TaskStatus? status,
    TaskOrigin? origin,
    bool includeArchived = false,
  }) async {
    lastStatus = status;
    lastOrigin = origin;
    lastIncludeArchived = includeArchived;

    return tasks
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
  Future<Task> createTask(Task task) {
    throw UnimplementedError();
  }

  @override
  Future<void> deletePermanently(String id) {
    throw UnimplementedError();
  }

  @override
  Future<Task?> getTaskByEcampusSourceKey(String sourceKey) {
    throw UnimplementedError();
  }

  @override
  Future<Task?> getTaskById(String id) {
    throw UnimplementedError();
  }

  @override
  Future<Task> markDeleted(String id) {
    throw UnimplementedError();
  }

  @override
  Future<Task> restoreTask(String id) {
    throw UnimplementedError();
  }

  @override
  Future<Task> updateTask(Task task) {
    throw UnimplementedError();
  }

  @override
  Future<Task> updateTaskStatus(String id, TaskStatus status) {
    throw UnimplementedError();
  }
}

class _FakeEcampusSyncService implements EcampusSyncService {
  _FakeEcampusSyncService({required this.syncedAt});

  final DateTime syncedAt;

  EcampusSession? lastSession;
  List<Task>? lastExistingTasks;
  DateTime? lastSyncedAt;

  @override
  Future<SyncResult> previewSync({
    required EcampusSession session,
    required List<Task> existingTasks,
    DateTime? syncedAt,
  }) async {
    lastSession = session;
    lastExistingTasks = existingTasks;
    lastSyncedAt = syncedAt;

    return SyncResult(items: const [], syncedAt: syncedAt ?? this.syncedAt);
  }
}

class _FakeEcampusSyncApplyService implements EcampusSyncApplyService {
  final importResult = [_task(id: 'imported')];
  final excludeResult = [_task(id: 'excluded', status: TaskStatus.excluded)];

  List<SyncItem>? lastImportItems;
  DateTime? lastImportSyncedAt;
  List<SyncItem>? lastExcludeItems;
  DateTime? lastExcludeSyncedAt;

  @override
  Future<List<Task>> importItems(
    Iterable<SyncItem> items, {
    DateTime? syncedAt,
  }) async {
    lastImportItems = items.toList(growable: false);
    lastImportSyncedAt = syncedAt;
    return importResult;
  }

  @override
  Future<List<Task>> excludeItems(
    Iterable<SyncItem> items, {
    DateTime? syncedAt,
  }) async {
    lastExcludeItems = items.toList(growable: false);
    lastExcludeSyncedAt = syncedAt;
    return excludeResult;
  }
}
