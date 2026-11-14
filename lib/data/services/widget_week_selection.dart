import '../models/task_models.dart';

class WeekWindow {
  const WeekWindow({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

/// 월요일 00:00 ~ 일요일 23:59:59.
WeekWindow weekWindowFor(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final start = today.subtract(Duration(days: now.weekday - DateTime.monday));
  final end = DateTime(start.year, start.month, start.day + 6, 23, 59, 59, 999);
  return WeekWindow(start: start, end: end);
}

bool isDueDateInWeek(DateTime dueDate, WeekWindow week) {
  final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
  final weekStartDay = DateTime(
    week.start.year,
    week.start.month,
    week.start.day,
  );
  final weekEndDay = DateTime(week.end.year, week.end.month, week.end.day);
  return !dueDay.isBefore(weekStartDay) && !dueDay.isAfter(weekEndDay);
}

bool isTaskEligibleForWeekWidget(Task task) {
  return task.status == TaskStatus.active ||
      task.status == TaskStatus.completed;
}

List<Task> tasksForWeek(List<Task> tasks, WeekWindow week) {
  return tasks
      .where(
        (task) =>
            task.dueDate != null &&
            isTaskEligibleForWeekWidget(task) &&
            isDueDateInWeek(task.dueDate!, week),
      )
      .toList(growable: false);
}

bool isTaskCompletedForWidget(Task task) {
  return task.status == TaskStatus.completed;
}

/// 미완료 우선, 같은 그룹은 마감일 오름차순.
int compareWidgetWeekTasks(Task a, Task b) {
  final aDone = isTaskCompletedForWidget(a);
  final bDone = isTaskCompletedForWidget(b);
  if (aDone != bDone) {
    return aDone ? 1 : -1;
  }

  final due = a.dueDate!.compareTo(b.dueDate!);
  if (due != 0) return due;
  final order = a.sortOrder.compareTo(b.sortOrder);
  if (order != 0) return order;
  final created = a.createdAt.compareTo(b.createdAt);
  return created != 0 ? created : a.id.compareTo(b.id);
}

/// 전체 일정을 미완료 우선으로 정렬한다. 페이지 분할은 Android에서 수행한다.
List<Task> selectWidgetWeekTasks(List<Task> weekTasks) {
  final sorted = [...weekTasks]..sort(compareWidgetWeekTasks);
  return sorted;
}

/// 진행률은 표시 5개가 아니라 이번 주 전체 일정 기준.
({int completedCount, int totalCount}) weekProgressCounts(
  List<Task> weekTasks,
) {
  final totalCount = weekTasks.length;
  final completedCount = weekTasks.where(isTaskCompletedForWidget).length;
  return (completedCount: completedCount, totalCount: totalCount);
}
