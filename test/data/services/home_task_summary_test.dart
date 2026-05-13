import 'package:flutter_test/flutter_test.dart';
import 'package:ku_task_management/data/models/task_models.dart';
import 'package:ku_task_management/data/services/home_task_summary.dart';

void main() {
  group('HomeTaskSummary', () {
    test('classifies active tasks by overdue, today, and urgent policy', () {
      final now = DateTime(2026, 5, 10, 10);
      final summary = HomeTaskSummary.fromTasks(
        tasks: [
          _task(id: 'overdue-yesterday', dueDate: DateTime(2026, 5, 9, 23, 59)),
          _task(id: 'overdue-today', dueDate: DateTime(2026, 5, 10, 9)),
          _task(id: 'today', dueDate: DateTime(2026, 5, 10, 23, 59)),
          _task(id: 'urgent', dueDate: DateTime(2026, 5, 12, 9)),
          _task(id: 'later', dueDate: DateTime(2026, 5, 14, 9)),
          _task(
            id: 'completed',
            dueDate: DateTime(2026, 5, 10, 23, 59),
            status: TaskStatus.completed,
          ),
        ],
        now: now,
        urgentDueDays: 3,
      );

      expect(summary.activeTasks.map((task) => task.id), [
        'overdue-yesterday',
        'overdue-today',
        'today',
        'urgent',
        'later',
      ]);
      expect(summary.overdueTasks.map((task) => task.id), [
        'overdue-yesterday',
        'overdue-today',
      ]);
      expect(summary.todayTasks.map((task) => task.id), ['today']);
      expect(summary.urgentTasks.map((task) => task.id), ['urgent']);
    });

    test('updates today and overdue buckets immediately after midnight', () {
      final tasks = [
        _task(id: 'yesterday-end', dueDate: DateTime(2026, 5, 10, 23, 59)),
        _task(id: 'new-today', dueDate: DateTime(2026, 5, 11, 23, 59)),
      ];

      final beforeMidnight = HomeTaskSummary.fromTasks(
        tasks: tasks,
        now: DateTime(2026, 5, 10, 23, 58),
        urgentDueDays: 3,
      );
      final afterMidnight = HomeTaskSummary.fromTasks(
        tasks: tasks,
        now: DateTime(2026, 5, 11),
        urgentDueDays: 3,
      );

      expect(beforeMidnight.todayTasks.map((task) => task.id), [
        'yesterday-end',
      ]);
      expect(beforeMidnight.urgentTasks.map((task) => task.id), ['new-today']);
      expect(afterMidnight.overdueTasks.map((task) => task.id), [
        'yesterday-end',
      ]);
      expect(afterMidnight.todayTasks.map((task) => task.id), ['new-today']);
    });

    test('sorts home due sections by due time then user order', () {
      final now = DateTime(2026, 5, 10, 8);
      final summary = HomeTaskSummary.fromTasks(
        tasks: [
          _task(id: 'late', dueDate: DateTime(2026, 5, 10, 18), sortOrder: 0),
          _task(id: 'early-b', dueDate: DateTime(2026, 5, 10, 9), sortOrder: 2),
          _task(id: 'early-a', dueDate: DateTime(2026, 5, 10, 9), sortOrder: 1),
        ],
        now: now,
        urgentDueDays: 3,
      );

      expect(summary.todayTasks.map((task) => task.id), [
        'early-a',
        'early-b',
        'late',
      ]);
    });
  });
}

Task _task({
  required String id,
  required DateTime dueDate,
  TaskStatus status = TaskStatus.active,
  int sortOrder = 0,
}) {
  final createdAt = DateTime(2026, 5, 1, 9);
  return Task(
    id: id,
    origin: TaskOrigin.personal,
    status: status,
    title: id,
    dueDate: dueDate,
    sortOrder: sortOrder,
    createdAt: createdAt,
    updatedAt: createdAt,
  );
}
