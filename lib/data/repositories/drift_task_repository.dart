import 'package:drift/drift.dart';
import '../../core/utils/entity_id.dart';
import '../local/app_database.dart' as db;
import '../local/mappers/task_mapper.dart';
import '../models/task_models.dart';
import 'task_repository.dart';

class DriftTaskRepository
    implements TaskRepository, TransactionalTaskRepository {
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
  Future<T> atomic<T>(Future<T> Function() action) =>
      _database.transaction(action);
  @override
  Future<void> recordImport(String id, int count, DateTime at) async {
    await _database
        .into(_database.importSessions)
        .insert(
          db.ImportSessionsCompanion.insert(
            id: id,
            sourceScopeId: db.AppDatabase.defaultSourceScope,
            startedAt: at,
            endedAt: Value(_now()),
            state: 'committed',
            appliedCount: Value(count),
          ),
        );
  }

  @override
  Future<List<Task>> getTasks({
    TaskStatus? status,
    TaskOrigin? origin,
    bool includeArchived = false,
  }) async {
    final query = _database.select(_database.tasks);
    if (status == TaskStatus.excluded) {
      return origin == TaskOrigin.personal ? [] : _excluded();
    }
    if (status != null) {
      switch (status) {
        case TaskStatus.active:
          query.where((t) => t.deletedAt.isNull() & t.completedAt.isNull());
        case TaskStatus.completed:
          query.where((t) => t.deletedAt.isNull() & t.completedAt.isNotNull());
        case TaskStatus.deleted:
          query.where((t) => t.deletedAt.isNotNull());
        case TaskStatus.excluded:
          break;
      }
    } else if (!includeArchived) {
      query.where((t) => t.deletedAt.isNull() & t.completedAt.isNull());
    }
    query.orderBy([
      (t) => OrderingTerm(expression: t.sortOrder),
      (t) => OrderingTerm(expression: t.createdAt),
      (t) => OrderingTerm(expression: t.id),
    ]);
    var result = await _mapRows(await query.get());
    if (includeArchived && status == null && origin != TaskOrigin.personal) {
      result = [...result, ...await _excluded()];
    }
    return origin == null
        ? result
        : result.where((t) => t.origin == origin).toList();
  }

  Future<List<Task>> _excluded() async =>
      (await (_database.select(
            _database.ecampusItems,
          )..where((t) => t.importState.equals('ignored'))).get())
          .map(_mapper.excluded)
          .toList();
  Future<List<Task>> _mapRows(List<db.Task> rows) async {
    final tags = <String, List<String>>{};
    final sources = <String, db.EcampusItem>{};
    for (var start = 0; start < rows.length; start += 500) {
      final ids = rows.skip(start).take(500).map((r) => r.id).toList();
      final links = await (_database.select(
        _database.taskTags,
      )..where((t) => t.taskId.isIn(ids) & t.deletedAt.isNull())).get();
      for (final link in links) {
        tags.putIfAbsent(link.taskId, () => []).add(link.tagId);
      }
      for (final source in await (_database.select(
        _database.ecampusItems,
      )..where((t) => t.taskId.isIn(ids))).get()) {
        sources[source.taskId!] = source;
      }
    }
    return rows
        .map(
          (r) => _mapper.fromRow(
            r,
            tagIds: tags[r.id] ?? [],
            source: sources[r.id],
          ),
        )
        .toList();
  }

  @override
  Future<Task?> getTaskById(String id) async {
    final row = await (_database.select(
      _database.tasks,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row != null) return (await _mapRows([row])).single;
    final item =
        await (_database.select(_database.ecampusItems)
              ..where((t) => t.id.equals(id) & t.importState.equals('ignored')))
            .getSingleOrNull();
    return item == null ? null : _mapper.excluded(item);
  }

  @override
  Future<Task?> getTaskByEcampusSourceKey(String key) async {
    final item =
        await (_database.select(_database.ecampusItems)..where(
              (t) =>
                  t.externalKey.equals(key) &
                  t.sourceScopeId.equals(db.AppDatabase.defaultSourceScope),
            ))
            .getSingleOrNull();
    if (item == null || item.importState == 'unreviewed') return null;
    return item.taskId == null
        ? _mapper.excluded(item)
        : getTaskById(item.taskId!);
  }

  void _validate(Task task) {
    if (task.folderIds.length > 1) {
      throw ArgumentError('일정은 폴더 하나에만 속할 수 있습니다.');
    }
    if (task.parentTaskId != null) {
      throw ArgumentError('하위 일정은 SubTask로 저장해야 합니다.');
    }
    if (task.status == TaskStatus.excluded && task.ecampus == null) {
      throw ArgumentError('제외 항목에는 eCampus 원본이 필요합니다.');
    }
  }

  Future<void> _validateRelations(Task task) async {
    if (task.folderIds.isNotEmpty) {
      final folder =
          await (_database.select(_database.folders)..where(
                (t) =>
                    t.id.equals(task.folderIds.single) & t.deletedAt.isNull(),
              ))
              .getSingleOrNull();
      if (folder == null) throw ArgumentError('존재하지 않거나 삭제된 폴더입니다.');
    }
    for (final id in task.tagIds.toSet()) {
      final tag =
          await (_database.select(_database.tags)
                ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
              .getSingleOrNull();
      if (tag == null) throw ArgumentError('존재하지 않거나 삭제된 태그입니다.');
    }
  }

  @override
  Future<Task> createTask(Task task) => atomic(() async {
    _validate(task);
    await _validateRelations(task);
    final key = task.ecampus?.sourceKey;
    if (key != null && key.isNotEmpty) {
      final existing = await getTaskByEcampusSourceKey(key);
      if (existing != null && existing.status != TaskStatus.excluded) {
        return existing;
      }
    }
    if (task.status == TaskStatus.excluded) {
      final source = await _writeSource(task, ignored: true);
      return _mapper.excluded(source);
    }
    final saved = task.sortOrder < 0
        ? _copyOrder(task, await _nextOrder())
        : task;
    await _database.into(_database.tasks).insert(_mapper.toCompanion(saved));
    await _replaceTags(saved);
    if (saved.ecampus != null) await _writeSource(saved);
    return (await getTaskById(saved.id))!;
  });
  @override
  Future<Task> updateTask(Task task) => atomic(() async {
    _validate(task);
    await _validateRelations(task);
    if (task.status == TaskStatus.excluded) {
      final existing = await (_database.select(
        _database.tasks,
      )..where((t) => t.id.equals(task.id))).getSingleOrNull();
      if (existing != null) {
        throw StateError('가져온 일정은 제외 상태로 바꾸지 않고 변경을 유지하거나 휴지통으로 이동합니다.');
      }
      return _mapper.excluded(await _writeSource(task, ignored: true));
    }
    final existing = await getTaskById(task.id);
    if (existing == null || existing.status == TaskStatus.excluded) {
      throw StateError('Task not found: ${task.id}');
    }
    final saved = task.sortOrder < 0
        ? _copyOrder(task, existing.sortOrder)
        : task;
    await (_database.update(
      _database.tasks,
    )..where((t) => t.id.equals(saved.id))).write(_mapper.toCompanion(saved));
    await _replaceTags(saved);
    if (saved.ecampus != null) await _writeSource(saved);
    return (await getTaskById(saved.id))!;
  });
  @override
  Future<Task> updateTaskStatus(String id, TaskStatus status) =>
      atomic(() async {
        if (status == TaskStatus.excluded) {
          throw ArgumentError('원본 제외는 별도 가져오기 선택입니다.');
        }
        final existing = await getTaskById(id);
        if (existing == null || existing.status == TaskStatus.excluded) {
          throw StateError('Task not found: $id');
        }
        final at = _now();
        await (_database.update(
          _database.tasks,
        )..where((t) => t.id.equals(id))).write(
          db.TasksCompanion(
            completedAt: status == TaskStatus.deleted
                ? const Value.absent()
                : Value(status == TaskStatus.completed ? at : null),
            deletedAt: Value(status == TaskStatus.deleted ? at : null),
            updatedAt: Value(at),
          ),
        );
        return (await getTaskById(id))!;
      });
  @override
  Future<void> updateTaskOrder(List<String> ids) => atomic(() async {
    for (var i = 0; i < ids.length; i++) {
      await (_database.update(
        _database.tasks,
      )..where((t) => t.id.equals(ids[i]))).write(
        db.TasksCompanion(sortOrder: Value(i), updatedAt: Value(_now())),
      );
    }
  });
  @override
  Future<Task> markDeleted(String id) =>
      updateTaskStatus(id, TaskStatus.deleted);
  @override
  Future<Task> restoreTask(String id) => atomic(() async {
    await (_database.update(
      _database.tasks,
    )..where((t) => t.id.equals(id))).write(
      db.TasksCompanion(deletedAt: const Value(null), updatedAt: Value(_now())),
    );
    final task = await getTaskById(id);
    if (task == null) throw StateError('Task not found: $id');
    return task;
  });
  @override
  Future<void> deletePermanently(String id) => atomic(() async {
    final task = await getTaskById(id);
    if (task == null) return;
    if (task.status == TaskStatus.excluded) {
      await (_database.update(
        _database.ecampusItems,
      )..where((t) => t.id.equals(id))).write(
        const db.EcampusItemsCompanion(importState: Value('unreviewed')),
      );
      return;
    }
    await _database
        .into(_database.deletedEntities)
        .insertOnConflictUpdate(
          db.DeletedEntitiesCompanion.insert(
            entityType: 'task',
            entityId: id,
            deletedAt: _now(),
          ),
        );
    await (_database.update(
      _database.ecampusItems,
    )..where((t) => t.taskId.equals(id))).write(
      const db.EcampusItemsCompanion(
        taskId: Value(null),
        importState: Value('ignored'),
      ),
    );
    await (_database.delete(
      _database.localNotificationSchedules,
    )..where((t) => t.taskId.equals(id))).go();
    await (_database.delete(
      _database.taskReminders,
    )..where((t) => t.taskId.equals(id))).go();
    await (_database.delete(
      _database.taskTags,
    )..where((t) => t.taskId.equals(id))).go();
    await (_database.delete(
      _database.subTasks,
    )..where((t) => t.taskId.equals(id))).go();
    await (_database.delete(
      _database.tasks,
    )..where((t) => t.id.equals(id))).go();
  });
  Future<void> _replaceTags(Task task) async {
    final at = _now();
    await (_database.update(
      _database.taskTags,
    )..where((t) => t.taskId.equals(task.id))).write(
      db.TaskTagsCompanion(deletedAt: Value(at), updatedAt: Value(at)),
    );
    for (final tag in task.tagIds.toSet()) {
      await _database
          .into(_database.taskTags)
          .insertOnConflictUpdate(
            db.TaskTagsCompanion.insert(
              taskId: task.id,
              tagId: tag,
              updatedAt: at,
            ),
          );
      await (_database.update(_database.taskTags)
            ..where((t) => t.taskId.equals(task.id) & t.tagId.equals(tag)))
          .write(const db.TaskTagsCompanion(deletedAt: Value(null)));
    }
  }

  Future<db.EcampusItem> _writeSource(Task task, {bool ignored = false}) async {
    final meta = task.ecampus!;
    final key = meta.sourceKey.isEmpty ? null : meta.sourceKey;
    final existing = key == null
        ? null
        : await (_database.select(_database.ecampusItems)..where(
                (t) =>
                    t.externalKey.equals(key) &
                    t.sourceScopeId.equals(db.AppDatabase.defaultSourceScope),
              ))
              .getSingleOrNull();
    String? courseId = existing?.courseId;
    final parts = key?.split(':');
    if (courseId == null && parts != null && parts.length == 3) {
      final course =
          await (_database.select(_database.ecampusCourses)..where(
                (t) =>
                    t.sourceScopeId.equals(db.AppDatabase.defaultSourceScope) &
                    t.externalCourseKey.equals(parts.first),
              ))
              .getSingleOrNull();
      courseId = course?.id ?? newEntityId();
      if (course == null) {
        await _database
            .into(_database.ecampusCourses)
            .insert(
              db.EcampusCoursesCompanion.insert(
                id: courseId,
                sourceScopeId: db.AppDatabase.defaultSourceScope,
                externalCourseKey: Value(parts.first),
                name: meta.sourceCourse ?? '',
                lastObservedAt: meta.lastSyncedAt ?? task.updatedAt,
              ),
            );
      }
    }
    final id = existing?.id ?? (ignored ? task.id : newEntityId());
    if (courseId != null) {
      await (_database.update(
        _database.ecampusCourses,
      )..where((t) => t.id.equals(courseId!))).write(
        db.EcampusCoursesCompanion(
          name: meta.sourceCourse == null
              ? const Value.absent()
              : Value(meta.sourceCourse!),
          lastObservedAt: Value(meta.lastSyncedAt ?? task.updatedAt),
        ),
      );
    }
    await _database
        .into(_database.ecampusItems)
        .insertOnConflictUpdate(
          db.EcampusItemsCompanion.insert(
            id: id,
            sourceScopeId: db.AppDatabase.defaultSourceScope,
            courseId: Value(courseId),
            externalKey: Value(key),
            sourceTitle: meta.sourceTitle ?? task.title,
            sourceCourse: Value(meta.sourceCourse),
            sourceType: Value(meta.sourceType?.name),
            sourceEndAt: Value(meta.sourceDueDate),
            taskId: Value(ignored ? null : task.id),
            importState: ignored ? 'ignored' : 'imported',
            firstObservedAt: existing?.firstObservedAt ?? task.createdAt,
            lastObservedAt: meta.lastSyncedAt ?? task.updatedAt,
          ),
        );
    return (await (_database.select(
      _database.ecampusItems,
    )..where((t) => t.id.equals(id))).getSingle());
  }

  Future<int> _nextOrder() async {
    final row =
        await (_database.select(_database.tasks)
              ..orderBy([(t) => OrderingTerm.desc(t.sortOrder)])
              ..limit(1))
            .getSingleOrNull();
    return (row?.sortOrder ?? -1) + 1;
  }

  Task _copyOrder(Task t, int order) => Task(
    id: t.id,
    origin: t.origin,
    status: t.status,
    title: t.title,
    dueDate: t.dueDate,
    priority: t.priority,
    memo: t.memo,
    tagIds: t.tagIds,
    folderIds: t.folderIds,
    ecampus: t.ecampus,
    sortOrder: order,
    createdAt: t.createdAt,
    updatedAt: t.updatedAt,
    completedAt: t.completedAt,
    deletedAt: t.deletedAt,
  );
}
