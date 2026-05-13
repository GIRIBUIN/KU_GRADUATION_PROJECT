import 'package:drift/drift.dart';

import '../local/app_database.dart' as db;
import '../local/mappers/sub_task_mapper.dart';
import '../models/task_models.dart';
import 'sub_task_repository.dart';

class DriftSubTaskRepository implements SubTaskRepository {
  const DriftSubTaskRepository({
    required db.AppDatabase database,
    DateTime Function()? now,
    SubTaskMapper mapper = const SubTaskMapper(),
  }) : _database = database,
       _now = now ?? DateTime.now,
       _mapper = mapper;

  final db.AppDatabase _database;
  final DateTime Function() _now;
  final SubTaskMapper _mapper;

  @override
  Future<List<SubTask>> getSubTasks(String taskId) async {
    final rows = await (_database.select(_database.subTasks)
          ..where((table) => table.taskId.equals(taskId))
          ..orderBy([(table) => OrderingTerm(expression: table.createdAt)]))
        .get();

    return rows.map(_mapper.fromRow).toList(growable: false);
  }

  @override
  Future<SubTask?> getSubTaskById(String id) async {
    final row = await (_database.select(
      _database.subTasks,
    )..where((table) => table.id.equals(id))).getSingleOrNull();

    return row == null ? null : _mapper.fromRow(row);
  }

  @override
  Future<SubTask> createSubTask(SubTask subTask) async {
    await _database
        .into(_database.subTasks)
        .insert(_mapper.toCompanion(subTask));
    return (await getSubTaskById(subTask.id))!;
  }

  @override
  Future<SubTask> updateSubTask(SubTask subTask) async {
    await (_database.update(_database.subTasks)
          ..where((table) => table.id.equals(subTask.id)))
        .write(_mapper.toCompanion(subTask));
    return (await getSubTaskById(subTask.id))!;
  }

  @override
  Future<SubTask> updateSubTaskDone(String id, bool isDone) async {
    final existing = await getSubTaskById(id);
    if (existing == null) {
      throw StateError('SubTask not found: $id');
    }

    return updateSubTask(
      SubTask(
        id: existing.id,
        taskId: existing.taskId,
        title: existing.title,
        isDone: isDone,
        createdAt: existing.createdAt,
        updatedAt: _now(),
      ),
    );
  }

  @override
  Future<void> deleteSubTask(String id) async {
    await (_database.delete(
      _database.subTasks,
    )..where((table) => table.id.equals(id))).go();
  }
}
