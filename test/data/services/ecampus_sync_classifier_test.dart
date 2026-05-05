import 'package:flutter_test/flutter_test.dart';
import 'package:ku_task_management/data/models/ecampus_models.dart';
import 'package:ku_task_management/data/models/task_models.dart';
import 'package:ku_task_management/data/services/ecampus_sync_classifier.dart';

void main() {
  const classifier = EcampusSyncClassifier();
  final syncedAt = DateTime(2026, 5, 5, 10);
  final dueDate = DateTime(2026, 5, 20);

  group('EcampusSyncClassifier', () {
    test('classifies a task without an existing sourceKey as newItem', () {
      final result = classifier.classify(
        parsedTasks: [_parsedTask(sourceKey: 'course:item:report')],
        existingTasks: const [],
        syncedAt: syncedAt,
      );

      expect(result.items.single.kind, SyncItemKind.newItem);
      expect(result.importCandidates.length, 1);
    });

    test('classifies completed, deleted, and excluded existing tasks', () {
      final parsedTasks = [
        _parsedTask(sourceKey: 'completed'),
        _parsedTask(sourceKey: 'deleted'),
        _parsedTask(sourceKey: 'excluded'),
      ];
      final existingTasks = [
        _task(sourceKey: 'completed', status: TaskStatus.completed),
        _task(sourceKey: 'deleted', status: TaskStatus.deleted),
        _task(sourceKey: 'excluded', status: TaskStatus.excluded),
      ];

      final result = classifier.classify(
        parsedTasks: parsedTasks,
        existingTasks: existingTasks,
        syncedAt: syncedAt,
      );

      expect(
        result.items.map((item) => item.kind),
        [
          SyncItemKind.completed,
          SyncItemKind.deleted,
          SyncItemKind.excluded,
        ],
      );
      expect(result.ignoredItems.length, 3);
    });

    test('classifies unchanged active existing task as alreadyImported', () {
      final parsedTask = _parsedTask(sourceKey: 'same', dueDate: dueDate);
      final existingTask = _task(
        sourceKey: 'same',
        status: TaskStatus.active,
        sourceDueDate: dueDate,
      );

      final result = classifier.classify(
        parsedTasks: [parsedTask],
        existingTasks: [existingTask],
        syncedAt: syncedAt,
      );

      expect(result.items.single.kind, SyncItemKind.alreadyImported);
      expect(result.ignoredItems.length, 1);
    });

    test('classifies changed active existing task as updateCandidate', () {
      final parsedTask = _parsedTask(
        sourceKey: 'changed',
        title: '변경된 과제',
        dueDate: dueDate,
      );
      final existingTask = _task(
        sourceKey: 'changed',
        status: TaskStatus.active,
        sourceTitle: '기존 과제',
        sourceDueDate: dueDate,
      );

      final result = classifier.classify(
        parsedTasks: [parsedTask],
        existingTasks: [existingTask],
        syncedAt: syncedAt,
      );

      expect(result.items.single.kind, SyncItemKind.updateCandidate);
      expect(result.importCandidates.length, 1);
    });

    test('classifies empty sourceKey as error', () {
      final result = classifier.classify(
        parsedTasks: [_parsedTask(sourceKey: '')],
        existingTasks: const [],
        syncedAt: syncedAt,
      );

      expect(result.items.single.kind, SyncItemKind.error);
      expect(result.errorItems.single.errorMessage, 'sourceKey 생성 실패');
    });
  });
}

ParsedEcampusTask _parsedTask({
  required String sourceKey,
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
    dueDate: dueDate,
  );
}

Task _task({
  required String sourceKey,
  required TaskStatus status,
  String sourceTitle = '자료구조 과제',
  String sourceCourse = '자료구조',
  EcampusTaskType sourceType = EcampusTaskType.report,
  DateTime? sourceDueDate,
}) {
  final now = DateTime(2026, 5, 5, 9);

  return Task(
    id: 'task-$sourceKey',
    origin: TaskOrigin.ecampus,
    status: status,
    title: sourceTitle,
    createdAt: now,
    updatedAt: now,
    ecampus: EcampusSyncMetadata(
      sourceKey: sourceKey,
      sourceTitle: sourceTitle,
      sourceCourse: sourceCourse,
      sourceType: sourceType,
      sourceDueDate: sourceDueDate,
    ),
  );
}
