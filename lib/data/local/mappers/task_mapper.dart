import 'package:drift/drift.dart';

import '../../models/task_models.dart' as models;
import '../app_database.dart' as db;

class TaskMapper {
  const TaskMapper();

  models.Task fromRow(
    db.Task row, {
    List<String> tagIds = const [],
    List<String> folderIds = const [],
  }) {
    return models.Task(
      id: row.id,
      origin: _parseOrigin(row.origin),
      status: _parseStatus(row.status),
      title: row.title,
      dueDate: row.dueDate,
      priority: row.priority == null ? null : _parsePriority(row.priority!),
      memo: row.memo,
      parentTaskId: row.parentTaskId,
      tagIds: tagIds,
      folderIds: folderIds,
      ecampus: row.ecampusSourceKey == null
          ? null
          : models.EcampusSyncMetadata(
              sourceKey: row.ecampusSourceKey!,
              sourceTitle: row.ecampusSourceTitle,
              sourceDueDate: row.ecampusSourceDueDate,
              sourceCourse: row.ecampusSourceCourse,
              sourceType: row.ecampusSourceType == null
                  ? null
                  : _parseEcampusTaskType(row.ecampusSourceType!),
              lastSyncedAt: row.ecampusLastSyncedAt,
            ),
      sortOrder: row.sortOrder,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      completedAt: row.completedAt,
      deletedAt: row.deletedAt,
    );
  }

  db.TasksCompanion toCompanion(models.Task task) {
    return db.TasksCompanion(
      id: Value(task.id),
      origin: Value(task.origin.name),
      status: Value(task.status.name),
      title: Value(task.title),
      dueDate: Value(task.dueDate),
      priority: Value(task.priority?.name),
      memo: Value(task.memo),
      parentTaskId: Value(task.parentTaskId),
      createdAt: Value(task.createdAt),
      updatedAt: Value(task.updatedAt),
      completedAt: Value(task.completedAt),
      deletedAt: Value(task.deletedAt),
      sortOrder: Value(task.sortOrder),
      ecampusSourceKey: Value(task.ecampus?.sourceKey),
      ecampusSourceTitle: Value(task.ecampus?.sourceTitle),
      ecampusSourceDueDate: Value(task.ecampus?.sourceDueDate),
      ecampusSourceCourse: Value(task.ecampus?.sourceCourse),
      ecampusSourceType: Value(task.ecampus?.sourceType?.name),
      ecampusLastSyncedAt: Value(task.ecampus?.lastSyncedAt),
    );
  }

  models.TaskOrigin _parseOrigin(String value) {
    return models.TaskOrigin.values.byName(value);
  }

  models.TaskStatus _parseStatus(String value) {
    return models.TaskStatus.values.byName(value);
  }

  models.TaskPriority _parsePriority(String value) {
    return models.TaskPriority.values.byName(value);
  }

  models.EcampusTaskType _parseEcampusTaskType(String value) {
    return models.EcampusTaskType.values.byName(value);
  }
}
