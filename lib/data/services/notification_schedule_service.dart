import '../models/task_models.dart';

class NotificationSchedule {
  const NotificationSchedule({
    required this.taskId,
    required this.settingId,
    required this.scheduledAt,
  });

  final String taskId;
  final String settingId;
  final DateTime scheduledAt;
}

class NotificationScheduleService {
  const NotificationScheduleService();

  NotificationSchedule? calculate({
    required Task task,
    required NotificationSetting setting,
    required DateTime now,
  }) {
    if (task.status != TaskStatus.active ||
        task.dueDate == null ||
        !setting.enabled ||
        setting.daysBeforeDue < 0) {
      return null;
    }

    final dueDate = task.dueDate!;
    final scheduledAt = dueDate.subtract(
      Duration(minutes: setting.daysBeforeDue),
    );

    if (scheduledAt.isBefore(now)) {
      return null;
    }

    return NotificationSchedule(
      taskId: task.id,
      settingId: setting.id,
      scheduledAt: scheduledAt,
    );
  }

  List<NotificationSchedule> calculateAll({
    required Iterable<Task> tasks,
    required Iterable<NotificationSetting> settings,
    required DateTime now,
  }) {
    final settingsByTaskId = {
      for (final setting in settings) setting.taskId: setting,
    };
    final schedules = <NotificationSchedule>[];

    for (final task in tasks) {
      final setting = settingsByTaskId[task.id];
      if (setting == null) {
        continue;
      }

      final schedule = calculate(task: task, setting: setting, now: now);
      if (schedule != null) {
        schedules.add(schedule);
      }
    }

    return schedules;
  }
}
