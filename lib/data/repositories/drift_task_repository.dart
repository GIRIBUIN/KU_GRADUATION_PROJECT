import 'package:drift/drift.dart';

import '../local/app_database.dart' as db;
import '../local/mappers/task_mapper.dart';
import '../models/task_models.dart';
import 'task_repository.dart';

class DriftTaskRepository implements TaskRepository {
  DriftTaskRepository({
    required db.AppDatabase database,
    DateTime Function()? now,
    TaskMapper mapper = const TaskMapper(),
  }) : _database = database,
       _now = now ?? DateTime.now,
       _mapper = mapper;

  final db.AppDatabase _database;
  final DateTime Function() _now;
  final TaskMapper _mapper;

  @override
  Future<List<Task>> getTasks({
    TaskStatus? status,
    TaskOrigin? origin,
    bool includeArchived = false,
  }) async {
    final query = _database.select(_database.tasks);

    if (status != null) {
      query.where((table) => table.status.equals(status.name));
    } else if (!includeArchived) {
      query.where((table) => table.status.equals(TaskStatus.active.name));
    }

    if (origin != null) {
      query.where((table) => table.origin.equals(origin.name));
    }

    query.orderBy([
      (table) => OrderingTerm(expression: table.sortOrder),
      (table) => OrderingTerm(expression: table.createdAt),
    ]);

    final rows = await query.get();
    return Future.wait(rows.map(_mapTaskWithRelations));
  }

  @override
  Future<Task?> getTaskById(String id) async {
    final row = await (_database.select(
      _database.tasks,
    )..where((table) => table.id.equals(id))).getSingleOrNull();

    if (row == null) {
      return null;
    }

    return _mapTaskWithRelations(row);
  }

  @override
  Future<Task?> getTaskByEcampusSourceKey(String sourceKey) async {
    final row =
        await (_database.select(_database.tasks)
              ..where((table) => table.ecampusSourceKey.equals(sourceKey)))
            .getSingleOrNull();

    if (row == null) {
      return null;
    }

    return _mapTaskWithRelations(row);
  }

  @override
  Future<Task> createTask(Task task) async {
    final taskToCreate = task.sortOrder < 0
        ? _copyTaskWithSortOrder(task, await _nextSortOrder())
        : task;

    await _database.transaction(() async {
      await _database
          .into(_database.tasks)
          .insert(_mapper.toCompanion(taskToCreate));
      await _replaceRelations(taskToCreate);
    });

    final created = await getTaskById(taskToCreate.id);
    return created!;
  }

  @override
  Future<Task> updateTask(Task task) async {
    final existing = await getTaskById(task.id);
    final taskToUpdate = task.sortOrder < 0 && existing != null
        ? _copyTaskWithSortOrder(task, existing.sortOrder)
        : task;

    await _database.transaction(() async {
      await (_database.update(_database.tasks)
            ..where((table) => table.id.equals(taskToUpdate.id)))
          .write(_mapper.toCompanion(taskToUpdate));
      await _replaceRelations(taskToUpdate);
    });

    final updated = await getTaskById(taskToUpdate.id);
    return updated!;
  }

  @override
  Future<Task> updateTaskStatus(String id, TaskStatus status) async {
    final existing = await getTaskById(id);
    if (existing == null) {
      throw StateError('Task not found: $id');
    }

    final now = _now();
    return updateTask(
      Task(
        id: existing.id,
        origin: existing.origin,
        status: status,
        title: existing.title,
        dueDate: existing.dueDate,
        priority: existing.priority,
        memo: existing.memo,
        parentTaskId: existing.parentTaskId,
        tagIds: existing.tagIds,
        folderIds: existing.folderIds,
        ecampus: existing.ecampus,
        sortOrder: existing.sortOrder,
        createdAt: existing.createdAt,
        updatedAt: now,
        completedAt: status == TaskStatus.completed
            ? now
            : existing.completedAt,
        deletedAt: status == TaskStatus.deleted ? now : existing.deletedAt,
      ),
    );
  }

  @override
  Future<void> updateTaskOrder(List<String> orderedTaskIds) async {
    await _database.transaction(() async {
      for (var index = 0; index < orderedTaskIds.length; index++) {
        await (_database.update(_database.tasks)
              ..where((table) => table.id.equals(orderedTaskIds[index])))
            .write(db.TasksCompanion(sortOrder: Value(index)));
      }
    });
  }

  @override
  Future<Task> markDeleted(String id) {
    return updateTaskStatus(id, TaskStatus.deleted);
  }

  @override
  Future<Task> restoreTask(String id) async {
    final existing = await getTaskById(id);
    if (existing == null) {
      throw StateError('Task not found: $id');
    }

    return updateTask(
      Task(
        id: existing.id,
        origin: existing.origin,
        status: TaskStatus.active,
        title: existing.title,
        dueDate: existing.dueDate,
        priority: existing.priority,
        memo: existing.memo,
        parentTaskId: existing.parentTaskId,
        tagIds: existing.tagIds,
        folderIds: existing.folderIds,
        ecampus: existing.ecampus,
        sortOrder: existing.sortOrder,
        createdAt: existing.createdAt,
        updatedAt: _now(),
      ),
    );
  }

  @override
  Future<void> deletePermanently(String id) async {
    await _database.transaction(() async {
      await (_database.delete(
        _database.taskTags,
      )..where((table) => table.taskId.equals(id))).go();
      await (_database.delete(
        _database.taskFolders,
      )..where((table) => table.taskId.equals(id))).go();
      await (_database.delete(
        _database.notificationSettings,
      )..where((table) => table.taskId.equals(id))).go();
      await (_database.delete(
        _database.subTasks,
      )..where((table) => table.taskId.equals(id))).go();
      await (_database.delete(
        _database.tasks,
      )..where((table) => table.id.equals(id))).go();
    });
  }

  Future<Task> _mapTaskWithRelations(db.Task row) async {
    final tagRows = await (_database.select(
      _database.taskTags,
    )..where((table) => table.taskId.equals(row.id))).get();
    final folderRows = await (_database.select(
      _database.taskFolders,
    )..where((table) => table.taskId.equals(row.id))).get();

    return _mapper.fromRow(
      row,
      tagIds: tagRows.map((row) => row.tagId).toList(growable: false),
      folderIds: folderRows.map((row) => row.folderId).toList(growable: false),
    );
  }

  Future<void> _replaceRelations(Task task) async {
    await (_database.delete(
      _database.taskTags,
    )..where((table) => table.taskId.equals(task.id))).go();
    await (_database.delete(
      _database.taskFolders,
    )..where((table) => table.taskId.equals(task.id))).go();

    for (final tagId in task.tagIds) {
      await _database
          .into(_database.taskTags)
          .insert(db.TaskTagsCompanion.insert(taskId: task.id, tagId: tagId));
    }

    for (final folderId in task.folderIds.take(1)) {
      await _database
          .into(_database.taskFolders)
          .insert(
            db.TaskFoldersCompanion.insert(taskId: task.id, folderId: folderId),
          );
    }
  }

  Future<int> _nextSortOrder() async {
    final rows =
        await (_database.select(_database.tasks)
              ..orderBy([
                (table) => OrderingTerm(
                  expression: table.sortOrder,
                  mode: OrderingMode.desc,
                ),
              ])
              ..limit(1))
            .get();

    if (rows.isEmpty) {
      return 0;
    }

    return rows.first.sortOrder + 1;
  }

  Task _copyTaskWithSortOrder(Task task, int sortOrder) {
    return Task(
      id: task.id,
      origin: task.origin,
      status: task.status,
      title: task.title,
      dueDate: task.dueDate,
      priority: task.priority,
      memo: task.memo,
      parentTaskId: task.parentTaskId,
      tagIds: task.tagIds,
      folderIds: task.folderIds,
      ecampus: task.ecampus,
      sortOrder: sortOrder,
      createdAt: task.createdAt,
      updatedAt: task.updatedAt,
      completedAt: task.completedAt,
      deletedAt: task.deletedAt,
    );
  }
}
