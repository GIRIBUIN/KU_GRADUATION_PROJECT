import '../models/task_models.dart';

enum CalendarTaskSource { all, personal, ecampus }

DateTime calendarDay(DateTime value) {
  // Calendar libraries use UTC date-only values; keep the displayed date intact.
  return DateTime(value.year, value.month, value.day);
}

class CalendarTaskIndex {
  CalendarTaskIndex.fromTasks(
    Iterable<Task> tasks, {
    bool includeCompleted = true,
    CalendarTaskSource source = CalendarTaskSource.all,
  }) {
    for (final task in tasks) {
      if (task.status != TaskStatus.active &&
          !(includeCompleted && task.status == TaskStatus.completed)) {
        continue;
      }
      if (source == CalendarTaskSource.personal &&
              task.origin != TaskOrigin.personal ||
          source == CalendarTaskSource.ecampus &&
              task.origin != TaskOrigin.ecampus) {
        continue;
      }
      final dueDate = task.dueDate;
      if (dueDate == null) {
        _undated.add(task);
      } else {
        _byDay.putIfAbsent(calendarDay(dueDate.toLocal()), () => []).add(task);
      }
    }
    for (final list in [..._byDay.values, _undated]) {
      list.sort(_compareTasks);
    }
  }

  final Map<DateTime, List<Task>> _byDay = {};
  final List<Task> _undated = [];

  List<Task> get undated => List.unmodifiable(_undated);
  Iterable<DateTime> get days => _byDay.keys;

  List<Task> tasksForDay(DateTime day) =>
      List.unmodifiable(_byDay[calendarDay(day)] ?? const <Task>[]);

  static int _compareTasks(Task a, Task b) {
    final status = (a.status == TaskStatus.completed ? 1 : 0).compareTo(
      b.status == TaskStatus.completed ? 1 : 0,
    );
    if (status != 0) return status;
    if (a.dueDate != null && b.dueDate != null) {
      final time = a.dueDate!.compareTo(b.dueDate!);
      if (time != 0) return time;
    }
    final order = a.sortOrder.compareTo(b.sortOrder);
    if (order != 0) return order;
    return a.id.compareTo(b.id);
  }
}
