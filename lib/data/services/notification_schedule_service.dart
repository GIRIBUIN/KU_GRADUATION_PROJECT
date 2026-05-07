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

    final time = _parseNotifyTime(setting.notifyTime);
    if (time == null) {
      return null;
    }

    final dueDate = task.dueDate!;
    final scheduledDate = DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day,
    ).subtract(Duration(days: setting.daysBeforeDue));
    final scheduledAt = DateTime(
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
      time.hour,
      time.minute,
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

  _NotifyTime? _parseNotifyTime(String value) {
    final match = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(value.trim());
    if (match == null) {
      return null;
    }

    final hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2)!);
    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return null;
    }

    return _NotifyTime(hour: hour, minute: minute);
  }
}

class _NotifyTime {
  const _NotifyTime({required this.hour, required this.minute});

  final int hour;
  final int minute;
}
