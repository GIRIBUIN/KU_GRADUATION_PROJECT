import '../models/ecampus_models.dart';
import '../models/task_models.dart';
import 'ecampus_auth_service.dart';
import 'ecampus_sync_classifier.dart';
import 'ecampus_sync_service.dart';
import 'ecampus_todo_service.dart';

class DefaultEcampusSyncService implements EcampusSyncService {
  const DefaultEcampusSyncService({
    required this.todoService,
    required this.classifier,
  });

  final EcampusTodoService todoService;
  final EcampusSyncClassifier classifier;

  @override
  Future<SyncResult> previewSync({
    required EcampusSession session,
    required List<Task> existingTasks,
    DateTime? syncedAt,
  }) async {
    final completedAt = syncedAt ?? DateTime.now();
    final parseResult = await todoService.fetchAndParse(session);
    final classified = classifier.classify(
      parsedTasks: parseResult.tasks,
      existingTasks: existingTasks,
      syncedAt: completedAt,
    );

    if (!parseResult.hasFailures) {
      return classified;
    }

    return SyncResult(
      items: [
        ...classified.items,
        for (final failure in parseResult.failures)
          SyncItem(kind: SyncItemKind.error, errorMessage: failure.reason),
      ],
      syncedAt: classified.syncedAt,
    );
  }
}
