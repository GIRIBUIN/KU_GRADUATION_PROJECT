import 'package:flutter_test/flutter_test.dart';
import 'package:ku_task_management/data/models/task_models.dart';
import 'package:ku_task_management/data/services/sub_task_progress.dart';

void main() {
  group('calculateSubTaskProgress', () {
    test('returns zero progress for empty subtasks', () {
      final progress = calculateSubTaskProgress(const []);

      expect(progress.hasSubTasks, isFalse);
      expect(progress.totalCount, 0);
      expect(progress.doneCount, 0);
      expect(progress.ratio, 0);
      expect(progress.percent, 0);
    });

    test('calculates done count, ratio, and percent', () {
      final progress = calculateSubTaskProgress([
        _subTask(id: 'sub-1', isDone: true),
        _subTask(id: 'sub-2', isDone: true),
        _subTask(id: 'sub-3'),
        _subTask(id: 'sub-4'),
      ]);

      expect(progress.hasSubTasks, isTrue);
      expect(progress.totalCount, 4);
      expect(progress.doneCount, 2);
      expect(progress.ratio, 0.5);
      expect(progress.percent, 50);
    });
  });
}

SubTask _subTask({required String id, bool isDone = false}) {
  final now = DateTime(2026, 5, 7, 10);

  return SubTask(
    id: id,
    taskId: 'task-1',
    title: '서브 작업',
    isDone: isDone,
    createdAt: now,
    updatedAt: now,
  );
}
