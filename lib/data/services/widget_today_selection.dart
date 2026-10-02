import '../models/task_models.dart';
import '../models/today_widget_data.dart';
import 'home_task_summary.dart';

/// 오늘 마감 active 일정만 최대 3개(마감 시각 순).
List<Task> selectWidgetTasks(HomeTaskSummary summary) {
  return summary.todayTasks.take(TodayWidgetData.maxTasks).toList(growable: false);
}
