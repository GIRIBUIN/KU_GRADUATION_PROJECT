import '../models/task_models.dart';

abstract class TaskRepository {
  Future<List<Task>> getTasks({
    TaskStatus? status,
    TaskOrigin? origin,
    bool includeArchived = false,
  });

  Future<Task?> getTaskById(String id);

  Future<Task?> getTaskByEcampusSourceKey(String sourceKey);

  Future<Task> createTask(Task task);

  Future<Task> updateTask(Task task);

  Future<Task> updateTaskStatus(String id, TaskStatus status);

  Future<Task> markDeleted(String id);

  Future<Task> restoreTask(String id);

  Future<void> deletePermanently(String id);
}
