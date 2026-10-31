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

    test(
      'deadline moves urgent to today to overdue at exact year rollover',
      () {
        final deadline = DateTime(2027, 1, 1);
        final tasks = [
          _task(id: 'boundary', dueDate: deadline),
          _task(id: 'undated', dueDate: null),
          _task(id: 'done', dueDate: deadline, status: TaskStatus.completed),
          _task(id: 'deleted', dueDate: deadline, status: TaskStatus.deleted),
        ];
        final before = HomeTaskSummary.fromTasks(
          tasks: tasks,
          now: deadline.subtract(const Duration(microseconds: 1)),
          urgentDueDays: 3,
        );
        final at = HomeTaskSummary.fromTasks(
          tasks: tasks,
          now: deadline,
          urgentDueDays: 3,
        );
        final after = HomeTaskSummary.fromTasks(
          tasks: tasks,
          now: deadline.add(const Duration(microseconds: 1)),
          urgentDueDays: 3,
        );
        expect(before.urgentTasks.map((t) => t.id), ['boundary']);
        expect(before.todayTasks, isEmpty);
        expect(before.overdueTasks, isEmpty);
        expect(at.todayTasks.map((t) => t.id), ['boundary']);
        expect(at.urgentTasks, isEmpty);
        expect(at.overdueTasks, isEmpty);
        expect(after.overdueTasks.map((t) => t.id), ['boundary']);
        expect(after.todayTasks, isEmpty);
        expect(after.urgentTasks, isEmpty);
        for (final summary in [before, at, after]) {
          expect(summary.activeTasks.map((t) => t.id), ['boundary', 'undated']);
        }
      },
    );

    for (final (now, days) in [
      (DateTime(2026, 12, 31, 12), 3),
      (DateTime(2028, 2, 28, 12), 1),
      (DateTime(2026, 10, 31, 12), 7),
    ]) {
      test(
        'urgent covers whole calendar days across $now with D+$days cutoff',
        () {
          final tasks = [
            _task(
              id: 'today',
              dueDate: DateTime(now.year, now.month, now.day, 23, 59),
            ),
            _task(
              id: 'tomorrow-start',
              dueDate: DateTime(now.year, now.month, now.day + 1),
            ),
            _task(
              id: 'cutoff-end',
              dueDate: DateTime(
                now.year,
                now.month,
                now.day + days,
                23,
                59,
                59,
                999,
              ),
            ),
            _task(
              id: 'outside',
              dueDate: DateTime(now.year, now.month, now.day + days + 1),
            ),
          ];
          final summary = HomeTaskSummary.fromTasks(
            tasks: tasks,
            now: now,
            urgentDueDays: days,
          );
          expect(summary.todayTasks.map((t) => t.id), ['today']);
          expect(summary.urgentTasks.map((t) => t.id), [
            'tomorrow-start',
            'cutoff-end',
          ]);
          expect(summary.overdueTasks, isEmpty);
          for (final disabled in [0, -1]) {
            expect(
              HomeTaskSummary.fromTasks(
                tasks: tasks,
                now: now,
                urgentDueDays: disabled,
              ).urgentTasks,
              isEmpty,
            );
          }
        },
      );
    }
  });
}

Task _task({
  required String id,
  required DateTime? dueDate,
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
