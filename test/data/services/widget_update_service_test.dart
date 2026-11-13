import 'package:flutter_test/flutter_test.dart';
import 'package:ku_task_management/data/models/task_models.dart';
import 'package:ku_task_management/data/services/widget_format.dart';
import 'package:ku_task_management/data/services/widget_today_selection.dart';
import 'package:ku_task_management/data/services/widget_week_selection.dart';

void main() {
  group('selectWidgetTasks', () {
    test('shows only today tasks without a query limit sorted by due time', () {
      final now = DateTime(2026, 5, 10, 10);
      final tasks = [
        _task(id: 'overdue', dueDate: DateTime(2026, 5, 9, 23, 59)),
        _task(id: 'today-late', dueDate: DateTime(2026, 5, 10, 18)),
        _task(id: 'today-early', dueDate: DateTime(2026, 5, 10, 11)),
        _task(id: 'urgent', dueDate: DateTime(2026, 5, 12, 9)),
      ];

      expect(selectWidgetTasks(tasks, now: now).map((task) => task.id), [
        'today-early',
        'today-late',
      ]);
    });

    test('returns empty list when there are no today tasks', () {
      final now = DateTime(2026, 5, 10, 10);
      final tasks = [
        _task(id: 'overdue', dueDate: DateTime(2026, 5, 9, 23, 59)),
        _task(id: 'urgent', dueDate: DateTime(2026, 5, 12, 9)),
      ];

      expect(selectWidgetTasks(tasks, now: now), isEmpty);
    });
  });

  for (final count in [0, 1, 3, 4, 5, 8, 10, 12]) {
    test(
      'widget queries retain all $count tasks including completed and past times',
      () {
        final now = DateTime(2026, 9, 16, 23);
        final tasks = List.generate(
          count,
          (i) => _task(
            id: '$i',
            dueDate: DateTime(2026, 9, 16, i),
            status: i.isEven ? TaskStatus.completed : TaskStatus.active,
          ),
        );
        final today = selectWidgetTasks(tasks, now: now);
        final weekly = selectWidgetWeekTasks(
          tasksForWeek(tasks, weekWindowFor(now)),
        );
        expect(today.length, count);
        expect(weekly.length, count);
        expect(today.map((t) => t.id), weekly.map((t) => t.id));
        final firstDone = today.indexWhere(
          (t) => t.status == TaskStatus.completed,
        );
        if (firstDone >= 0) {
          expect(
            today
                .skip(firstDone)
                .every((t) => t.status == TaskStatus.completed),
            isTrue,
          );
        }
      },
    );
  }

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
      final weekTasks = tasksForWeek([
        _task(
          id: 'done',
          dueDate: DateTime(2026, 9, 15, 18),
          status: TaskStatus.completed,
        ),
        _task(id: 'later', dueDate: DateTime(2026, 9, 19, 18)),
        _task(id: 'soon', dueDate: DateTime(2026, 9, 16, 11)),
        _task(id: 'next', dueDate: DateTime(2026, 9, 17, 9)),
        _task(id: 'outside', dueDate: DateTime(2026, 9, 27, 9)),
      ], week);

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
        _task(id: 'done', dueDate: dueDate, status: TaskStatus.completed),
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
      final weekTasks = tasksForWeek([
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
      ], week);

      expect(weekProgressCounts(weekTasks).completedCount, 2);
      expect(weekProgressCounts(weekTasks).totalCount, 6);
      expect(selectWidgetWeekTasks(weekTasks).length, 6);
    });
  });

  test('midnight and Sunday to Monday change both query windows', () {
    final sunday = DateTime(2026, 11, 15, 23, 59, 59);
    final monday = DateTime(2026, 11, 16);
    final tasks = [
      _task(id: 'sunday', dueDate: sunday),
      _task(id: 'monday', dueDate: monday),
    ];
    expect(selectWidgetTasks(tasks, now: sunday).single.id, 'sunday');
    expect(selectWidgetTasks(tasks, now: monday).single.id, 'monday');
    expect(tasksForWeek(tasks, weekWindowFor(sunday)).single.id, 'sunday');
    expect(tasksForWeek(tasks, weekWindowFor(monday)).single.id, 'monday');
  });

  test('all completed tasks stay visible and have full progress', () {
    final now = DateTime(2026, 11, 13);
    final tasks = List.generate(
      6,
      (i) => _task(
        id: '$i',
        dueDate: now.add(Duration(hours: i)),
        status: TaskStatus.completed,
      ),
    ).reversed.toList();
    expect(selectWidgetTasks(tasks, now: now).map((t) => t.id), [
      '0',
      '1',
      '2',
      '3',
      '4',
      '5',
    ]);
    expect(weekProgressCounts(tasks).completedCount, 6);
    expect(weekProgressCounts(tasks).totalCount, 6);
  });

  group('widget format helpers', () {
    test('formats today and weekly labels', () {
      expect(formatWidgetHeaderDate(DateTime(2026, 9, 11)), '9월 11일 (금)');
      expect(formatWidgetTime(DateTime(2026, 9, 11, 9)), '09:00');
      expect(
        formatWidgetWeekRange(DateTime(2026, 9, 14), DateTime(2026, 9, 20)),
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

      expect(accentColorForTask(task, tagsById: tagsById), '#3B82F6');
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
