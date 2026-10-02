import 'package:flutter_test/flutter_test.dart';
import 'package:ku_task_management/data/models/task_models.dart';
import 'package:ku_task_management/data/services/home_task_summary.dart';
import 'package:ku_task_management/data/services/widget_format.dart';
import 'package:ku_task_management/data/services/widget_today_selection.dart';
import 'package:ku_task_management/data/services/widget_week_selection.dart';

void main() {
  group('selectWidgetTasks', () {
    test('shows only today tasks up to three items sorted by due time', () {
      final now = DateTime(2026, 5, 10, 10);
      final summary = HomeTaskSummary.fromTasks(
        tasks: [
          _task(id: 'overdue', dueDate: DateTime(2026, 5, 9, 23, 59)),
          _task(id: 'today-late', dueDate: DateTime(2026, 5, 10, 18)),
          _task(id: 'today-early', dueDate: DateTime(2026, 5, 10, 11)),
          _task(id: 'urgent', dueDate: DateTime(2026, 5, 12, 9)),
        ],
        now: now,
        urgentDueDays: 3,
      );

      expect(selectWidgetTasks(summary).map((task) => task.id), [
        'today-early',
        'today-late',
      ]);
    });

    test('returns empty list when there are no today tasks', () {
      final now = DateTime(2026, 5, 10, 10);
      final summary = HomeTaskSummary.fromTasks(
        tasks: [
          _task(id: 'overdue', dueDate: DateTime(2026, 5, 9, 23, 59)),
          _task(id: 'urgent', dueDate: DateTime(2026, 5, 12, 9)),
        ],
        now: now,
        urgentDueDays: 3,
      );

      expect(selectWidgetTasks(summary), isEmpty);
    });
  });

  group('weekWindowFor', () {
    test('returns Monday through Sunday for the current week', () {
      final now = DateTime(2026, 9, 14, 15);
      final week = weekWindowFor(now);

      expect(week.start, DateTime(2026, 9, 14));
      expect(week.end, DateTime(2026, 9, 20, 23, 59, 59, 999));
    });
  });

  group('selectWidgetWeekTasks', () {
    test('shows incomplete tasks first then due date within each group', () {
      final week = weekWindowFor(DateTime(2026, 9, 16, 10));
      final weekTasks = tasksForWeek(
        [
          _task(
            id: 'done',
            dueDate: DateTime(2026, 9, 15, 18),
            status: TaskStatus.completed,
          ),
          _task(id: 'later', dueDate: DateTime(2026, 9, 19, 18)),
          _task(id: 'soon', dueDate: DateTime(2026, 9, 16, 11)),
          _task(id: 'next', dueDate: DateTime(2026, 9, 17, 9)),
          _task(id: 'outside', dueDate: DateTime(2026, 9, 27, 9)),
        ],
        week,
      );

      expect(selectWidgetWeekTasks(weekTasks).map((task) => task.id), [
        'soon',
        'next',
        'later',
        'done',
      ]);
    });

    test('prefers incomplete tasks when due dates match', () {
      final dueDate = DateTime(2026, 9, 16, 11);
      final weekTasks = [
        _task(
          id: 'done',
          dueDate: dueDate,
          status: TaskStatus.completed,
        ),
        _task(id: 'active', dueDate: dueDate),
      ];

      expect(selectWidgetWeekTasks(weekTasks).map((task) => task.id), [
        'active',
        'done',
      ]);
    });
  });

  group('weekProgressCounts', () {
    test('counts all week tasks, not just displayed five', () {
      final week = weekWindowFor(DateTime(2026, 9, 16, 10));
      final weekTasks = tasksForWeek(
        [
          _task(
            id: 'done-1',
            dueDate: DateTime(2026, 9, 15, 18),
            status: TaskStatus.completed,
          ),
          _task(id: 'active-1', dueDate: DateTime(2026, 9, 16, 11)),
          _task(id: 'active-2', dueDate: DateTime(2026, 9, 17, 9)),
          _task(id: 'active-3', dueDate: DateTime(2026, 9, 18, 9)),
          _task(
            id: 'done-2',
            dueDate: DateTime(2026, 9, 19, 9),
            status: TaskStatus.completed,
          ),
          _task(id: 'active-4', dueDate: DateTime(2026, 9, 20, 9)),
        ],
        week,
      );

      expect(weekProgressCounts(weekTasks).completedCount, 2);
      expect(weekProgressCounts(weekTasks).totalCount, 6);
      expect(selectWidgetWeekTasks(weekTasks).length, 5);
    });
  });

  group('widget format helpers', () {
    test('formats today and weekly labels', () {
      expect(
        formatWidgetHeaderDate(DateTime(2026, 9, 11)),
        '9월 11일 (금)',
      );
      expect(
        formatWidgetTime(DateTime(2026, 9, 11, 9)),
        '09:00',
      );
      expect(
        formatWidgetWeekRange(
          DateTime(2026, 9, 14),
          DateTime(2026, 9, 20),
        ),
        '9월 14일 (월) ~ 9월 20일 (일)',
      );
    });

    test('uses first tag color for accent bar', () {
      final task = Task(
        id: 'task-1',
        origin: TaskOrigin.personal,
        status: TaskStatus.active,
        title: 'task',
        tagIds: const ['tag-1'],
        createdAt: DateTime(2026, 5, 1),
        updatedAt: DateTime(2026, 5, 1),
      );
      final tagsById = {
        'tag-1': Tag(
          id: 'tag-1',
          name: 'OS',
          color: '3B82F6',
          createdAt: DateTime(2026, 5, 1),
          updatedAt: DateTime(2026, 5, 1),
        ),
      };

      expect(
        accentColorForTask(task, tagsById: tagsById),
        '#3B82F6',
      );
    });
  });
}

Task _task({
  required String id,
  required DateTime dueDate,
  TaskOrigin origin = TaskOrigin.personal,
  TaskStatus status = TaskStatus.active,
}) {
  final createdAt = DateTime(2026, 5, 1, 9);
  return Task(
    id: id,
    origin: origin,
    status: status,
    title: id,
    dueDate: dueDate,
    createdAt: createdAt,
    updatedAt: createdAt,
    completedAt: status == TaskStatus.completed ? createdAt : null,
  );
}
