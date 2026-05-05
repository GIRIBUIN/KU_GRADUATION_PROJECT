import '../models/task_models.dart';

abstract class NotificationRepository {
  Future<NotificationSetting?> getByTaskId(String taskId);

  Future<NotificationSetting> save(NotificationSetting notification);

  Future<void> deleteByTaskId(String taskId);
}
