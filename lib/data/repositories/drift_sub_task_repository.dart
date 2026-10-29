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
    final rows =
        await (_database.select(_database.subTasks)
              ..where(
                (table) =>
                    table.taskId.equals(taskId) & table.deletedAt.isNull(),
              )
              ..orderBy([(table) => OrderingTerm(expression: table.position)]))
            .get();

    return rows.map(_mapper.fromRow).toList(growable: false);
  }

  @override
  Future<SubTask?> getSubTaskById(String id) async {
    final row =
        await (_database.select(
              _database.subTasks,
            )..where((table) => table.id.equals(id) & table.deletedAt.isNull()))
            .getSingleOrNull();

    return row == null ? null : _mapper.fromRow(row);
  }

  @override
  Future<SubTask> createSubTask(SubTask subTask) =>
      _database.transaction(() async {
        final last =
            await (_database.select(_database.subTasks)
                  ..where((t) => t.taskId.equals(subTask.taskId))
                  ..orderBy([(t) => OrderingTerm.desc(t.position)])
                  ..limit(1))
                .getSingleOrNull();
        await _database
            .into(_database.subTasks)
            .insert(
              _mapper
                  .toCompanion(subTask)
                  .copyWith(position: Value((last?.position ?? -1) + 1)),
            );
        return (await getSubTaskById(subTask.id))!;
      });

  @override
  Future<SubTask> updateSubTask(SubTask subTask) async {
    final existing = await getSubTaskById(subTask.id);
    if (existing == null || existing.taskId != subTask.taskId) {
      throw StateError('하위 일정의 소속을 바꿀 수 없습니다.');
    }
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
    await (_database.update(
      _database.subTasks,
    )..where((t) => t.id.equals(id))).write(
      db.SubTasksCompanion(deletedAt: Value(_now()), updatedAt: Value(_now())),
    );
  }
}
