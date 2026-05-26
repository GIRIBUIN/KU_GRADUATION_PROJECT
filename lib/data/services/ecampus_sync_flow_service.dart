import '../models/ecampus_models.dart';
import '../models/task_models.dart';
import '../repositories/task_repository.dart';
import 'ecampus_auth_service.dart';
import 'ecampus_sync_apply_service.dart';
import 'ecampus_sync_service.dart';

abstract class EcampusSyncFlowService {
  Future<SyncResult> preview({
    required EcampusSession session,
    DateTime? syncedAt,
  });

  Future<List<Task>> importItems(
    Iterable<SyncItem> items, {
    DateTime? syncedAt,
  });

  Future<List<Task>> excludeItems(
    Iterable<SyncItem> items, {
    DateTime? syncedAt,
  });

  Future<void> allowExcludedTasks(Iterable<Task> tasks);
}

class DefaultEcampusSyncFlowService implements EcampusSyncFlowService {
  const DefaultEcampusSyncFlowService({
    required TaskRepository taskRepository,
    required EcampusSyncService syncService,
    required EcampusSyncApplyService applyService,
  }) : _taskRepository = taskRepository,
       _syncService = syncService,
       _applyService = applyService;

  final TaskRepository _taskRepository;
  final EcampusSyncService _syncService;
  final EcampusSyncApplyService _applyService;

  @override
  Future<SyncResult> preview({
    required EcampusSession session,
    DateTime? syncedAt,
  }) async {
    final existingTasks = await _taskRepository.getTasks(
      origin: TaskOrigin.ecampus,
      includeArchived: true,
    );

    final result = await _syncService.previewSync(
      session: session,
      existingTasks: existingTasks,
      syncedAt: syncedAt,
    );

    if (result.errorItems.isEmpty) {
      final autoCompletedItems = await _completeMissingFutureDueTasks(
        existingTasks: existingTasks,
        result: result,
      );
      if (autoCompletedItems.isNotEmpty) {
        return SyncResult(
          items: [...result.items, ...autoCompletedItems],
          syncedAt: result.syncedAt,
        );
      }
    }

    return result;
  }

  @override
  Future<List<Task>> importItems(
    Iterable<SyncItem> items, {
    DateTime? syncedAt,
  }) {
    return _applyService.importItems(items, syncedAt: syncedAt);
  }

  @override
  Future<List<Task>> excludeItems(
    Iterable<SyncItem> items, {
    DateTime? syncedAt,
  }) {
    return _applyService.excludeItems(items, syncedAt: syncedAt);
  }

  @override
  Future<void> allowExcludedTasks(Iterable<Task> tasks) async {
    for (final task in tasks) {
      final sourceKey = task.ecampus?.sourceKey.trim();
      if (task.status != TaskStatus.excluded ||
          sourceKey == null ||
          sourceKey.isEmpty) {
        continue;
      }

      await _taskRepository.deletePermanently(task.id);
    }
  }

  Future<List<SyncItem>> _completeMissingFutureDueTasks({
    required List<Task> existingTasks,
    required SyncResult result,
  }) async {
    final completedItems = <SyncItem>[];
    final syncedSourceKeys = result.items
        .map((item) => item.parsedTask?.sourceKey.trim())
        .whereType<String>()
        .where((sourceKey) => sourceKey.isNotEmpty)
        .toSet();

    for (final task in existingTasks) {
      final sourceKey = task.ecampus?.sourceKey.trim();
      if (task.status != TaskStatus.active ||
          sourceKey == null ||
          sourceKey.isEmpty ||
          syncedSourceKeys.contains(sourceKey)) {
        continue;
      }

      final dueDate = task.ecampus?.sourceDueDate ?? task.dueDate;
      if (dueDate != null && dueDate.isAfter(result.syncedAt)) {
        final completedTask = await _taskRepository.updateTaskStatus(
          task.id,
          TaskStatus.completed,
        );
        completedItems.add(
          SyncItem(kind: SyncItemKind.completed, existingTask: completedTask),
        );
      }
    }

    return completedItems;
  }
}
