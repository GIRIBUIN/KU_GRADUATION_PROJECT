import 'package:drift/drift.dart';

import '../../models/task_models.dart' as models;
import '../app_database.dart' as db;

class SubTaskMapper {
  const SubTaskMapper();

  models.SubTask fromRow(db.SubTask row) {
    return models.SubTask(
      id: row.id,
      taskId: row.taskId,
      title: row.title,
      isDone: row.completedAt != null,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  db.SubTasksCompanion toCompanion(models.SubTask subTask) {
    return db.SubTasksCompanion(
      id: Value(subTask.id),
      taskId: Value(subTask.taskId),
      title: Value(subTask.title),
      completedAt: Value(subTask.isDone ? subTask.updatedAt : null),
      createdAt: Value(subTask.createdAt),
      updatedAt: Value(subTask.updatedAt),
    );
  }
}
