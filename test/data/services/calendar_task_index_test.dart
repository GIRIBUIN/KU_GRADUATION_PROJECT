import 'package:flutter_test/flutter_test.dart';
import 'package:ku_task_management/data/models/task_models.dart';
import 'package:ku_task_management/data/services/calendar_task_index.dart';

void main() {
  final day = DateTime(2026, 10, 3);

  test('calendar date-only values preserve their displayed date', () {
    expect(calendarDay(DateTime.utc(2026, 10, 3)), day);
    final index = CalendarTaskIndex.fromTasks([
      task('local', due: DateTime(2026, 10, 3, 23)),
    ]);
    expect(index.tasksForDay(DateTime.utc(2026, 10, 3)).single.id, 'local');
  });

  test(
    'uses app due dates for personal and imported tasks, excluding deleted and excluded',
    () {
      final index = CalendarTaskIndex.fromTasks([
        task('personal', due: DateTime(2026, 10, 3, 12)),
        task(
          'ecampus',
          due: DateTime(2026, 10, 3, 9),
          origin: TaskOrigin.ecampus,
        ),
        task('deleted', due: day, status: TaskStatus.deleted),
        task('excluded', due: day, status: TaskStatus.excluded),
        task('tomorrow', due: DateTime(2026, 10, 4)),
      ]);
      expect(index.tasksForDay(day).map((task) => task.id), [
        'ecampus',
        'personal',
      ]);
      expect(index.tasksForDay(DateTime(2026, 10, 4)).single.id, 'tomorrow');
    },
  );

  test('keeps undated tasks separate and can filter source and completion', () {
    final tasks = [
      task('personal', due: day),
      task('done', due: day, status: TaskStatus.completed),
      task('ecampus', due: day, origin: TaskOrigin.ecampus),
      task('undated'),
    ];
    final index = CalendarTaskIndex.fromTasks(tasks);
    expect(index.undated.single.id, 'undated');
    expect(index.tasksForDay(day).last.id, 'done');
    expect(
      CalendarTaskIndex.fromTasks(
        tasks,
        includeCompleted: false,
      ).tasksForDay(day).length,
      2,
    );
    expect(
      CalendarTaskIndex.fromTasks(
        tasks,
        source: CalendarTaskSource.ecampus,
      ).tasksForDay(day).single.id,
      'ecampus',
    );
    expect(
      CalendarTaskIndex.fromTasks(
        tasks,
        source: CalendarTaskSource.personal,
      ).tasksForDay(day).length,
      2,
    );
  });

  test('groups UTC timestamps by their local date and preserves leap day', () {
    final utc = DateTime.utc(2028, 2, 29, 14);
    final local = utc.toLocal();
    final index = CalendarTaskIndex.fromTasks([task('utc', due: utc)]);
    expect(
      index.tasksForDay(DateTime(local.year, local.month, local.day)).single.id,
      'utc',
    );
    final leap = CalendarTaskIndex.fromTasks([
      task('leap', due: DateTime(2028, 2, 29, 23, 59)),
    ]);
    expect(leap.tasksForDay(DateTime(2028, 2, 29)).single.id, 'leap');
    expect(leap.tasksForDay(DateTime(2028, 3, 1)), isEmpty);
  });

  test(
    'reflects edits and removals without copying tasks into another store',
    () {
      final updated = CalendarTaskIndex.fromTasks([
        task('moved', due: DateTime(2026, 11, 1)),
        task('removed', due: day, status: TaskStatus.deleted),
      ]);
      expect(updated.tasksForDay(day), isEmpty);
      expect(updated.tasksForDay(DateTime(2026, 11, 1)).single.id, 'moved');
    },
  );
}

Task task(
  String id, {
  DateTime? due,
  TaskStatus status = TaskStatus.active,
  TaskOrigin origin = TaskOrigin.personal,
}) => Task(
  id: id,
  origin: origin,
  status: status,
  title: id,
  dueDate: due,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);
