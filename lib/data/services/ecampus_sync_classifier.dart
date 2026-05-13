import '../models/ecampus_models.dart';
import '../models/task_models.dart';

class EcampusSyncClassifier {
  const EcampusSyncClassifier();

  SyncResult classify({
    required List<ParsedEcampusTask> parsedTasks,
    required List<Task> existingTasks,
    required DateTime syncedAt,
  }) {
    final existingBySourceKey = <String, Task>{};

    for (final task in existingTasks) {
      final sourceKey = task.ecampus?.sourceKey;
      if (sourceKey == null || sourceKey.isEmpty) {
        continue;
      }
      existingBySourceKey[sourceKey] = task;
    }

    final items = parsedTasks.map((parsedTask) {
      if (parsedTask.sourceKey.trim().isEmpty) {
        return SyncItem(
          kind: SyncItemKind.error,
          parsedTask: parsedTask,
          errorMessage: 'sourceKey 생성 실패',
        );
      }

      final existingTask = existingBySourceKey[parsedTask.sourceKey];
      if (existingTask == null) {
        return SyncItem(kind: SyncItemKind.newItem, parsedTask: parsedTask);
      }

      return SyncItem(
        kind: _classifyExisting(parsedTask, existingTask),
        parsedTask: parsedTask,
        existingTask: existingTask,
      );
    }).toList(growable: false);

    return SyncResult(items: items, syncedAt: syncedAt);
  }

  SyncItemKind _classifyExisting(
    ParsedEcampusTask parsedTask,
    Task existingTask,
  ) {
    return switch (existingTask.status) {
      TaskStatus.completed => SyncItemKind.completed,
      TaskStatus.deleted => SyncItemKind.deleted,
      TaskStatus.excluded => SyncItemKind.excluded,
      TaskStatus.active => _hasSourceChanged(parsedTask, existingTask)
          ? SyncItemKind.updateCandidate
          : SyncItemKind.alreadyImported,
    };
  }

  bool _hasSourceChanged(ParsedEcampusTask parsedTask, Task existingTask) {
    final ecampus = existingTask.ecampus;
    if (ecampus == null) {
      return true;
    }

    return ecampus.sourceTitle != parsedTask.title ||
        ecampus.sourceDueDate != parsedTask.dueDate ||
        ecampus.sourceCourse != parsedTask.course ||
        ecampus.sourceType != parsedTask.type;
  }
}
