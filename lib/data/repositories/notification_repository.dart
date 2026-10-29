import '../models/task_models.dart';

abstract class NotificationRepository {
  Future<NotificationSetting?> getByTaskId(String taskId);

  Future<List<NotificationSetting>> getAll();

  Future<NotificationSetting> save(NotificationSetting notification);

  Future<void> deleteByTaskId(String taskId);
}

abstract interface class LocalNotificationStateStore {
  Future<int> notificationId(String taskId, int preferred);
  Future<void> recordSchedule(
    String taskId,
    DateTime? scheduledAt, {
    String? error,
  });
}
