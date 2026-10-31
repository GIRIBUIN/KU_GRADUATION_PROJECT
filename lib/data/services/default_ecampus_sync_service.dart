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
      detectMissing: parseResult.isComplete && !parseResult.hasFailures,
    );

    if (!parseResult.hasFailures && parseResult.isComplete) {
      return classified;
    }

    return SyncResult(
      items: [
        ...classified.items,
        for (final failure in parseResult.failures)
          SyncItem(kind: SyncItemKind.error, errorMessage: failure.reason),
        if (!parseResult.isComplete && !parseResult.hasFailures)
          SyncItem(
            kind: SyncItemKind.error,
            errorMessage:
                '누락 검토를 생략했습니다: '
                '${parseResult.incompleteReasons.isEmpty ? "전체 목록 여부를 확인할 수 없습니다" : parseResult.incompleteReasons.join(" / ")}. '
                '조회된 항목은 가져올 수 있습니다.',
          ),
      ],
      syncedAt: classified.syncedAt,
    );
  }
}
