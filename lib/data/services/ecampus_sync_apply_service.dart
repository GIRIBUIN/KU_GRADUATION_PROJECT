import '../models/ecampus_models.dart';
import '../models/task_models.dart';
import '../repositories/task_repository.dart';

abstract class EcampusSyncApplyService {
  Future<List<Task>> importItems(
    Iterable<SyncItem> items, {
    DateTime? syncedAt,
  });

  Future<List<Task>> excludeItems(
    Iterable<SyncItem> items, {
    DateTime? syncedAt,
  });
}

class DefaultEcampusSyncApplyService implements EcampusSyncApplyService {
  DefaultEcampusSyncApplyService({
    required TaskRepository taskRepository,
    DateTime Function()? now,
    String Function(ParsedEcampusTask parsedTask, TaskStatus status)? createId,
  }) : _taskRepository = taskRepository,
       _now = now ?? DateTime.now,
       _createId = createId ?? _defaultCreateId;

  final TaskRepository _taskRepository;
  final DateTime Function() _now;
  final String Function(ParsedEcampusTask parsedTask, TaskStatus status)
  _createId;

  @override
  Future<List<Task>> importItems(
    Iterable<SyncItem> items, {
    DateTime? syncedAt,
  }) async {
    final appliedAt = syncedAt ?? _now();
    final appliedTasks = <Task>[];

    for (final item in items) {
      final parsedTask = item.parsedTask;
      if (parsedTask == null) {
        continue;
      }

      switch (item.kind) {
        case SyncItemKind.newItem:
          appliedTasks.add(await _createTask(parsedTask, appliedAt));
        case SyncItemKind.updateCandidate:
          final updated = await _updateTask(item, parsedTask, appliedAt);
          if (updated != null) {
            appliedTasks.add(updated);
          }
        case SyncItemKind.alreadyImported:
        case SyncItemKind.completed:
        case SyncItemKind.deleted:
        case SyncItemKind.excluded:
        case SyncItemKind.error:
          break;
      }
    }

    return appliedTasks;
  }

  @override
  Future<List<Task>> excludeItems(
    Iterable<SyncItem> items, {
    DateTime? syncedAt,
  }) async {
    final appliedAt = syncedAt ?? _now();
    final appliedTasks = <Task>[];

    for (final item in items) {
      final parsedTask = item.parsedTask;
      if (parsedTask == null || item.kind == SyncItemKind.error) {
        continue;
      }

      final existingTask = await _findExistingTask(item, parsedTask);
      if (existingTask == null) {
        appliedTasks.add(
          await _createTask(parsedTask, appliedAt, status: TaskStatus.excluded),
        );
        continue;
      }

      if (existingTask.status == TaskStatus.completed ||
          existingTask.status == TaskStatus.deleted) {
        continue;
      }

      appliedTasks.add(
        await _taskRepository.updateTask(
          _copyTaskFromParsed(
            existingTask,
            parsedTask,
            appliedAt,
            status: TaskStatus.excluded,
          ),
        ),
      );
    }

    return appliedTasks;
  }

  Future<Task> _createTask(
    ParsedEcampusTask parsedTask,
    DateTime appliedAt, {
    TaskStatus status = TaskStatus.active,
  }) {
    return _taskRepository.createTask(
      Task(
        id: _createId(parsedTask, status),
        origin: TaskOrigin.ecampus,
        status: status,
        title: parsedTask.title,
        dueDate: parsedTask.dueDate,
        priority: TaskPriority.medium,
        memo: parsedTask.course,
        ecampus: _metadataFromParsed(parsedTask, appliedAt),
        createdAt: appliedAt,
        updatedAt: appliedAt,
      ),
    );
  }

  Future<Task?> _updateTask(
    SyncItem item,
    ParsedEcampusTask parsedTask,
    DateTime appliedAt,
  ) async {
    final existingTask = await _findExistingTask(item, parsedTask);
    if (existingTask == null || existingTask.status != TaskStatus.active) {
      return null;
    }

    return _taskRepository.updateTask(
      _copyTaskFromParsed(existingTask, parsedTask, appliedAt),
    );
  }

  Future<Task?> _findExistingTask(SyncItem item, ParsedEcampusTask parsedTask) {
    final existingTask = item.existingTask;
    if (existingTask != null) {
      return Future.value(existingTask);
    }

    return _taskRepository.getTaskByEcampusSourceKey(parsedTask.sourceKey);
  }

  Task _copyTaskFromParsed(
    Task existingTask,
    ParsedEcampusTask parsedTask,
    DateTime appliedAt, {
    TaskStatus? status,
  }) {
    return Task(
      id: existingTask.id,
      origin: existingTask.origin,
      status: status ?? existingTask.status,
      title: parsedTask.title,
      dueDate: parsedTask.dueDate,
      priority: existingTask.priority,
      memo: parsedTask.course,
      parentTaskId: existingTask.parentTaskId,
      tagIds: existingTask.tagIds,
      folderIds: existingTask.folderIds,
      ecampus: _metadataFromParsed(parsedTask, appliedAt),
      createdAt: existingTask.createdAt,
      updatedAt: appliedAt,
      completedAt: existingTask.completedAt,
      deletedAt: existingTask.deletedAt,
    );
  }

  EcampusSyncMetadata _metadataFromParsed(
    ParsedEcampusTask parsedTask,
    DateTime syncedAt,
  ) {
    return EcampusSyncMetadata(
      sourceKey: parsedTask.sourceKey,
      sourceTitle: parsedTask.title,
      sourceDueDate: parsedTask.dueDate,
      sourceCourse: parsedTask.course,
      sourceType: parsedTask.type,
      lastSyncedAt: syncedAt,
    );
  }

  static String _defaultCreateId(
    ParsedEcampusTask parsedTask,
    TaskStatus status,
  ) {
    final safeSourceKey = parsedTask.sourceKey
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    final suffix = safeSourceKey.isEmpty
        ? DateTime.now().microsecondsSinceEpoch.toString()
        : safeSourceKey;

    return 'ecampus_${status.name}_$suffix';
  }
}
