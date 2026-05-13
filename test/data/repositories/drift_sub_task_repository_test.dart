import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ku_task_management/data/local/app_database.dart'
    show AppDatabase;
import 'package:ku_task_management/data/models/task_models.dart' as models;
import 'package:ku_task_management/data/repositories/drift_sub_task_repository.dart';
import 'package:ku_task_management/data/repositories/drift_task_repository.dart';

void main() {
  late AppDatabase database;
  late DriftTaskRepository taskRepository;
  late DriftSubTaskRepository subTaskRepository;

  final now = DateTime(2026, 5, 7, 10);

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    taskRepository = DriftTaskRepository(database: database, now: () => now);
    subTaskRepository = DriftSubTaskRepository(
      database: database,
      now: () => now,
    );

    await taskRepository.createTask(_task(id: 'task-1'));
  });

  tearDown(() async {
    await database.close();
  });

  group('DriftSubTaskRepository', () {
    test('creates and lists subtasks by task id', () async {
      await subTaskRepository.createSubTask(
        _subTask(id: 'sub-2', title: '두 번째'),
      );
      await subTaskRepository.createSubTask(
        _subTask(
          id: 'sub-1',
          title: '첫 번째',
          createdAt: now.subtract(const Duration(minutes: 1)),
        ),
      );

      final subTasks = await subTaskRepository.getSubTasks('task-1');

      expect(subTasks.map((subTask) => subTask.id), ['sub-1', 'sub-2']);
    });

    test('updates subtask title and done state', () async {
      await subTaskRepository.createSubTask(_subTask(id: 'sub-1'));

      final updated = await subTaskRepository.updateSubTask(
        _subTask(id: 'sub-1', title: '수정된 서브 작업', isDone: true),
      );

      expect(updated.title, '수정된 서브 작업');
      expect(updated.isDone, isTrue);
    });

    test('updates only done state and refreshed updatedAt', () async {
      await subTaskRepository.createSubTask(_subTask(id: 'sub-1'));

      final updated = await subTaskRepository.updateSubTaskDone('sub-1', true);

      expect(updated.isDone, isTrue);
      expect(updated.updatedAt, now);
    });

    test('deletes a subtask', () async {
      await subTaskRepository.createSubTask(_subTask(id: 'sub-1'));

      await subTaskRepository.deleteSubTask('sub-1');

      expect(await subTaskRepository.getSubTasks('task-1'), isEmpty);
    });
  });
}

models.Task _task({required String id}) {
  final now = DateTime(2026, 5, 7, 9);

  return models.Task(
    id: id,
    origin: models.TaskOrigin.personal,
    status: models.TaskStatus.active,
    title: '운영체제 팀플 과제',
    createdAt: now,
    updatedAt: now,
  );
}

models.SubTask _subTask({
  required String id,
  String taskId = 'task-1',
  String title = '자료 조사',
  bool isDone = false,
  DateTime? createdAt,
}) {
  final now = DateTime(2026, 5, 7, 10);

  return models.SubTask(
    id: id,
    taskId: taskId,
    title: title,
    isDone: isDone,
    createdAt: createdAt ?? now,
    updatedAt: createdAt ?? now,
  );
}
