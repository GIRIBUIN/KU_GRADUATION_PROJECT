import '../models/task_models.dart';
import 'widget_week_selection.dart';

/// 오늘 날짜에 마감인 전체 일정. 이미 지난 마감 시각도 포함한다.
List<Task> selectWidgetTasks(List<Task> tasks, {required DateTime now}) {
  return selectWidgetWeekTasks(
    tasks.where((task) {
      final due = task.dueDate;
      return due != null &&
          isTaskEligibleForWeekWidget(task) &&
          due.year == now.year &&
          due.month == now.month &&
          due.day == now.day;
    }).toList(),
  );
}
