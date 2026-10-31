import 'package:drift/drift.dart';
import '../../models/task_models.dart' as models;
import '../app_database.dart' as db;

class TaskMapper {
  const TaskMapper();
  models.Task fromRow(
    db.Task row, {
    List<String> tagIds = const [],
    db.EcampusItem? source,
  }) => models.Task(
    id: row.id,
    origin: source == null
        ? models.TaskOrigin.personal
        : models.TaskOrigin.ecampus,
    status: row.deletedAt != null
        ? models.TaskStatus.deleted
        : row.completedAt != null
        ? models.TaskStatus.completed
        : models.TaskStatus.active,
    title: row.title,
    dueDate: row.dueDate,
    priority: row.priority == null
        ? null
        : models.TaskPriority.values.byName(row.priority!),
    memo: row.memo,
    tagIds: tagIds,
    folderIds: [row.folderId],
    ecampus: source == null ? null : metadata(source),
    sortOrder: row.sortOrder,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    completedAt: row.completedAt,
    deletedAt: row.deletedAt,
  );
  models.EcampusSyncMetadata metadata(db.EcampusItem row) =>
      models.EcampusSyncMetadata(
        sourceKey: row.externalKey ?? '',
        sourceTitle: row.sourceTitle,
        sourceDueDate: row.sourceEndAt,
        sourceCourse: row.sourceCourse,
        sourceType: row.sourceType == null
            ? null
            : models.EcampusTaskType.values.firstWhere(
                (v) => v.name == row.sourceType,
                orElse: () => models.EcampusTaskType.unknown,
              ),
        lastSyncedAt: row.lastObservedAt,
      );
  models.Task excluded(db.EcampusItem row) => models.Task(
    id: row.id,
    origin: models.TaskOrigin.ecampus,
    status: models.TaskStatus.excluded,
    title: row.sourceTitle,
    dueDate: row.sourceEndAt,
    ecampus: metadata(row),
    createdAt: row.firstObservedAt,
    updatedAt: row.lastObservedAt,
  );
  db.TasksCompanion toCompanion(models.Task task) => db.TasksCompanion(
    id: Value(task.id),
    title: Value(task.title),
    dueDate: Value(task.dueDate),
    priority: Value(task.priority?.name),
    memo: Value(task.memo),
    folderId: Value(task.listId),
    createdAt: Value(task.createdAt),
    updatedAt: Value(task.updatedAt),
    sortOrder: Value(task.sortOrder),
    completedAt: Value(
      task.status == models.TaskStatus.active
          ? null
          : task.status == models.TaskStatus.completed
          ? task.completedAt ?? task.updatedAt
          : task.completedAt,
    ),
    deletedAt: Value(
      task.status == models.TaskStatus.deleted
          ? task.deletedAt ?? task.updatedAt
          : null,
    ),
  );
}
