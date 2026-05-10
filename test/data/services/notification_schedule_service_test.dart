import 'package:flutter_test/flutter_test.dart';
import 'package:ku_task_management/data/models/task_models.dart';
import 'package:ku_task_management/data/services/notification_schedule_service.dart';

void main() {
  const service = NotificationScheduleService();
  final now = DateTime(2026, 5, 7, 10);

  group('NotificationScheduleService', () {
    test('calculates schedule from due date and minutes before', () {
      final schedule = service.calculate(
        task: _task(dueDate: DateTime(2026, 5, 20, 23, 59)),
        setting: _setting(minutesBeforeDue: 90),
        now: now,
      );

      expect(schedule, isNotNull);
      expect(schedule!.taskId, 'task-1');
      expect(schedule.settingId, 'notification-1');
      expect(schedule.scheduledAt, DateTime(2026, 5, 20, 22, 29));
    });

    test('excludes completed, deleted, and excluded tasks', () {
      for (final status in [
        TaskStatus.completed,
        TaskStatus.deleted,
        TaskStatus.excluded,
      ]) {
        final schedule = service.calculate(
          task: _task(status: status),
          setting: _setting(),
          now: now,
        );

        expect(schedule, isNull);
      }
    });

    test('excludes tasks without due date', () {
      final schedule = service.calculate(
        task: _task(hasDueDate: false),
        setting: _setting(),
        now: now,
      );

      expect(schedule, isNull);
    });

    test('excludes disabled notification settings', () {
      final schedule = service.calculate(
        task: _task(),
        setting: _setting(enabled: false),
        now: now,
      );

      expect(schedule, isNull);
    });

    test('excludes schedules that are already in the past', () {
      final schedule = service.calculate(
        task: _task(dueDate: DateTime(2026, 5, 7, 10, 30)),
        setting: _setting(minutesBeforeDue: 60),
        now: now,
      );

      expect(schedule, isNull);
    });

    test('excludes schedules that are exactly now', () {
      final schedule = service.calculate(
        task: _task(dueDate: now),
        setting: _setting(minutesBeforeDue: 0),
        now: now,
      );

      expect(schedule, isNull);
    });

    test('excludes negative minutesBeforeDue values', () {
      final schedule = service.calculate(
        task: _task(),
        setting: _setting(minutesBeforeDue: -1),
        now: now,
      );

      expect(schedule, isNull);
    });

    test('calculates schedules for tasks that have matching settings', () {
      final schedules = service.calculateAll(
        tasks: [
          _task(id: 'task-1'),
          _task(id: 'task-2', status: TaskStatus.completed),
          _task(id: 'task-3'),
        ],
        settings: [
          _setting(id: 'notification-1', taskId: 'task-1'),
          _setting(id: 'notification-2', taskId: 'task-2'),
        ],
        now: now,
      );

      expect(schedules.map((schedule) => schedule.taskId), ['task-1']);
    });
  });
}

Task _task({
  String id = 'task-1',
  TaskStatus status = TaskStatus.active,
  DateTime? dueDate,
  bool hasDueDate = true,
}) {
  final createdAt = DateTime(2026, 5, 7, 9);

  return Task(
    id: id,
    origin: TaskOrigin.personal,
    status: status,
    title: '자료구조 과제',
    dueDate: hasDueDate ? dueDate ?? DateTime(2026, 5, 20) : null,
    createdAt: createdAt,
    updatedAt: createdAt,
  );
}

NotificationSetting _setting({
  String id = 'notification-1',
  String taskId = 'task-1',
  bool enabled = true,
  int minutesBeforeDue = 60,
}) {
  return NotificationSetting(
    id: id,
    taskId: taskId,
    enabled: enabled,
    daysBeforeDue: minutesBeforeDue,
    notifyTime: 'relative',
  );
}
