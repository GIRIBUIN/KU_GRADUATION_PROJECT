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

    return _syncService.previewSync(
      session: session,
      existingTasks: existingTasks,
      syncedAt: syncedAt,
    );
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
}
