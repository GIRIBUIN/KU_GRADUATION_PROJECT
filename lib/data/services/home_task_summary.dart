import '../models/task_models.dart';

class HomeTaskSummary {
  const HomeTaskSummary({
    required this.activeTasks,
    required this.overdueTasks,
    required this.todayTasks,
    required this.urgentTasks,
  });

  factory HomeTaskSummary.fromTasks({
    required List<Task> tasks,
    required DateTime now,
    required int urgentDueDays,
  }) {
    final activeTasks = tasks
        .where((task) => task.status == TaskStatus.active)
        .toList(growable: false);
    final overdueTasks = activeTasks
        .where((task) => isTaskOverdue(task, now: now))
        .toList();
    final todayTasks = activeTasks
        .where((task) => isTaskDueToday(task, now: now))
        .toList();
    final urgentTasks = activeTasks
        .where((task) => isTaskUrgent(task, now: now, days: urgentDueDays))
        .toList();

    overdueTasks.sort(_compareHomeDueDate);
    todayTasks.sort(_compareHomeDueDate);
    urgentTasks.sort(_compareHomeDueDate);

    return HomeTaskSummary(
      activeTasks: activeTasks,
      overdueTasks: overdueTasks,
      todayTasks: todayTasks,
      urgentTasks: urgentTasks,
    );
  }

  final List<Task> activeTasks;
  final List<Task> overdueTasks;
  final List<Task> todayTasks;
  final List<Task> urgentTasks;
}

bool isTaskDueToday(Task task, {required DateTime now}) {
  final dueDate = task.dueDate;
  if (dueDate == null || isTaskOverdue(task, now: now)) {
    return false;
  }
  return _isSameDate(dueDate, now);
}

bool isTaskUrgent(Task task, {required DateTime now, required int days}) {
  final dueDate = task.dueDate;
  if (dueDate == null ||
      days <= 0 ||
      isTaskOverdue(task, now: now) ||
      isTaskDueToday(task, now: now)) {
    return false;
  }

  final startOfToday = DateTime(now.year, now.month, now.day);
  final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
  final difference = dueDay.difference(startOfToday).inDays;
  return difference > 0 && difference <= days;
}

bool isTaskOverdue(Task task, {required DateTime now}) {
  final dueDate = task.dueDate;
  return dueDate != null && isDueDateOverdue(dueDate, now: now);
}

bool isDueDateOverdue(DateTime dueDate, {required DateTime now}) {
  return dueDate.isBefore(now);
}

int _compareHomeDueDate(Task a, Task b) {
  final aDueDate = a.dueDate;
  final bDueDate = b.dueDate;
  if (aDueDate == null && bDueDate == null) {
    return _compareHomeFallback(a, b);
  }
  if (aDueDate == null) {
    return 1;
  }
  if (bDueDate == null) {
    return -1;
  }

  final dueDate = aDueDate.compareTo(bDueDate);
  if (dueDate != 0) {
    return dueDate;
  }
  return _compareHomeFallback(a, b);
}

int _compareHomeFallback(Task a, Task b) {
  final sortOrder = a.sortOrder.compareTo(b.sortOrder);
  if (sortOrder != 0) {
    return sortOrder;
  }
  return a.createdAt.compareTo(b.createdAt);
}

bool _isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
