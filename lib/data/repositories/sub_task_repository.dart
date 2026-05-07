import '../models/task_models.dart';

abstract class SubTaskRepository {
  Future<List<SubTask>> getSubTasks(String taskId);

  Future<SubTask?> getSubTaskById(String id);

  Future<SubTask> createSubTask(SubTask subTask);

  Future<SubTask> updateSubTask(SubTask subTask);

  Future<SubTask> updateSubTaskDone(String id, bool isDone);

  Future<void> deleteSubTask(String id);
}
