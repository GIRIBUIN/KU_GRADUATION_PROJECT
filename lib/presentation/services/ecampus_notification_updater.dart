import '../../data/models/task_models.dart';
import '../../data/repositories/notification_repository.dart';
import 'local_notification_service.dart';

/// Called only after the selected eCampus batch has committed.
class EcampusNotificationUpdater {
  const EcampusNotificationUpdater({
    required this.repository,
    required this.notifications,
  });

  final NotificationRepository repository;
  final LocalNotificationService notifications;

  Future<void> afterCommit(Task before, Task after) async {
    if (before.status == TaskStatus.active &&
        after.status != TaskStatus.active) {
      await notifications.cancelTaskNotification(after.id);
      return;
    }
    if (before.dueDate == after.dueDate || after.status != TaskStatus.active) {
      return;
    }
    final setting = await repository.getByTaskId(after.id);
    if (setting == null || !setting.enabled) return;
    await notifications.scheduleTaskNotification(task: after, setting: setting);
  }
}
