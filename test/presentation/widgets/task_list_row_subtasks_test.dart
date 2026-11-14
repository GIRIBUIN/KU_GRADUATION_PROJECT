import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ku_task_management/data/local/app_database.dart'
    show AppDatabase;
import 'package:ku_task_management/data/models/task_models.dart';
import 'package:ku_task_management/data/repositories/drift_sub_task_repository.dart';
import 'package:ku_task_management/data/repositories/drift_task_repository.dart';
import 'package:ku_task_management/data/repositories/sub_task_repository.dart';
import 'package:ku_task_management/presentation/widgets/task_list_row.dart';

void main() {
  setUpAll(() => initializeDateFormatting('ko_KR'));
  final now = DateTime(2026, 11, 15, 10);
  const parentKey = ValueKey('parent-row');
  late AppDatabase database;
  late DriftTaskRepository tasks;
  late DriftSubTaskRepository subTasks;
  late _Repository repository;
  late Task parent;
  late int opened;
  late int toggled;
  late VoidCallback refreshRows;
  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    tasks = DriftTaskRepository(database: database);
    subTasks = DriftSubTaskRepository(database: database);
    repository = _Repository(subTasks);
    parent = await tasks.createTask(
      Task(
        id: 'parent',
        title: '부모 할 일',
        origin: TaskOrigin.personal,
        status: TaskStatus.active,
        priority: TaskPriority.high,
        createdAt: now,
        updatedAt: now,
      ),
    );
    opened = 0;
    toggled = 0;
  });
  tearDown(() => database.close());

  Future<void> addChild([String id = 'child']) => subTasks.createSubTask(
    SubTask(
      id: id,
      taskId: parent.id,
      title: '서브 작업 $id',
      isDone: false,
      createdAt: now,
      updatedAt: now,
    ),
  );
  Finder child([String id = 'child']) =>
      find.byKey(ValueKey<Object>(('subtask', parentKey, id)));
  Future<void> open(
    WidgetTester tester, {
    TaskStatus? status,
    bool settle = true,
  }) async {
    final task = status == null
        ? parent
        : Task(
            id: parent.id,
            title: parent.title,
            origin: parent.origin,
            status: status,
            createdAt: now,
            updatedAt: now,
          );
    var version = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, update) {
              refreshRows = () => update(() => version++);
              return buildTaskListRow(
                key: parentKey,
                task: task,
                subTaskRepository: repository,
                subTaskVersion: version,
                onSubTasksChanged: refreshRows,
                leading: Checkbox(value: false, onChanged: (_) => toggled++),
                onTap: () => opened++,
              );
            },
          ),
        ),
      ),
    );
    if (settle) await tester.pumpAndSettle();
  }

  testWidgets(
    'tap expands and collapses; parent checkbox and long press stay independent',
    (tester) async {
      await addChild();
      await open(tester);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      expect(child(), findsNothing);
      await tester.tap(find.byKey(parentKey));
      await tester.pumpAndSettle();
      expect(child(), findsOneWidget);
      expect(opened, 0);
      await tester.tap(
        find.descendant(
          of: find.byKey(parentKey),
          matching: find.byType(Checkbox),
        ),
      );
      await tester.pumpAndSettle();
      expect(toggled, 1);
      expect(child(), findsOneWidget);
      await tester.tap(find.byKey(parentKey));
      await tester.pumpAndSettle();
      expect(child(), findsNothing);
      expect(repository.reads, 1);
      await tester.longPress(find.byKey(parentKey));
      await tester.pumpAndSettle();
      expect(opened, 1);
      expect(child(), findsNothing);
    },
  );

  testWidgets(
    'child completion persists without completing parent and preserves expansion on refresh',
    (tester) async {
      await addChild();
      await open(tester);
      await tester.tap(find.byKey(parentKey));
      await tester.pumpAndSettle();
      final checkbox = find.descendant(
        of: child(),
        matching: find.byType(Checkbox),
      );
      await tester.tap(checkbox);
      await tester.pumpAndSettle();
      expect((await subTasks.getSubTaskById('child'))!.isDone, isTrue);
      expect(tester.widget<Checkbox>(checkbox).value, isTrue);
      expect((await tasks.getTaskById(parent.id))!.status, TaskStatus.active);
      await addChild('second');
      refreshRows();
      await tester.pumpAndSettle();
      expect(child('second'), findsOneWidget);
      await subTasks.deleteSubTask('second');
      refreshRows();
      await tester.pumpAndSettle();
      expect(child('second'), findsNothing);
      expect(child(), findsOneWidget);
    },
  );

  testWidgets('child save failure preserves checkbox and can retry', (
    tester,
  ) async {
    await addChild();
    await open(tester);
    await tester.tap(find.byKey(parentKey));
    await tester.pumpAndSettle();
    final checkbox = find.descendant(
      of: child(),
      matching: find.byType(Checkbox),
    );
    repository.failWrite = true;
    await tester.tap(checkbox);
    await tester.pumpAndSettle();
    expect(tester.widget<Checkbox>(checkbox).value, isFalse);
    expect((await subTasks.getSubTaskById('child'))!.isDone, isFalse);
    expect(find.textContaining('서브 작업을 저장하지 못했습니다.'), findsOneWidget);
    repository.failWrite = false;
    await tester.tap(checkbox);
    await tester.pumpAndSettle();
    expect((await subTasks.getSubTaskById('child'))!.isDone, isTrue);
    expect(child(), findsOneWidget);
  });

  testWidgets(
    'empty task opens details and archived scopes retain selection without fetching children',
    (tester) async {
      await open(tester);
      await tester.tap(find.byKey(parentKey));
      await tester.pumpAndSettle();
      expect(opened, 1);
      expect(find.byIcon(Icons.chevron_right), findsNothing);
      for (final status in [TaskStatus.deleted, TaskStatus.excluded]) {
        await tester.pumpWidget(const SizedBox.shrink());
        final reads = repository.reads;
        await open(tester, status: status);
        final beforeSelection = opened;
        await tester.tap(find.byKey(parentKey));
        await tester.pumpAndSettle();
        expect(opened, beforeSelection + 1);
        expect(repository.reads, reads);
        expect(child(), findsNothing);
      }
    },
  );

  testWidgets(
    'tap during initial load waits before choosing expansion instead of detail',
    (tester) async {
      await addChild();
      final pending = Completer<List<SubTask>>();
      repository.pending = pending.future;
      await open(tester, settle: false);
      await tester.tap(find.byKey(parentKey));
      await tester.pump();
      expect(opened, 0);
      pending.complete(await subTasks.getSubTasks(parent.id));
      await tester.pumpAndSettle();
      expect(child(), findsOneWidget);
      expect(opened, 0);
    },
  );

  testWidgets('load failure is reported and later tap retries', (tester) async {
    await addChild();
    repository.failRead = true;
    await open(tester);
    await tester.tap(find.byKey(parentKey));
    await tester.pumpAndSettle();
    expect(find.textContaining('서브 작업을 불러오지 못했습니다.'), findsOneWidget);
    expect(opened, 0);
    repository.failRead = false;
    await tester.tap(find.byKey(parentKey));
    await tester.pumpAndSettle();
    expect(child(), findsOneWidget);
  });
}

class _Repository extends Fake implements SubTaskRepository {
  _Repository(this.delegate);
  final SubTaskRepository delegate;
  int reads = 0;
  bool failRead = false;
  bool failWrite = false;
  Future<List<SubTask>>? pending;
  @override
  Future<List<SubTask>> getSubTasks(String taskId) async {
    reads++;
    if (failRead) throw StateError('injected read failure');
    return pending ?? delegate.getSubTasks(taskId);
  }

  @override
  Future<SubTask> updateSubTaskDone(String id, bool isDone) {
    if (failWrite) throw StateError('injected write failure');
    return delegate.updateSubTaskDone(id, isDone);
  }
}
