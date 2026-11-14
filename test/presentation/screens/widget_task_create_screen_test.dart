import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ku_task_management/core/utils/list_defaults.dart';
import 'package:ku_task_management/data/local/app_database.dart'
    show AppDatabase;
import 'package:ku_task_management/data/models/task_models.dart';
import 'package:ku_task_management/data/repositories/drift_tag_repository.dart';
import 'package:ku_task_management/data/repositories/drift_folder_repository.dart';
import 'package:ku_task_management/data/repositories/folder_repository.dart';
import 'package:ku_task_management/data/repositories/drift_task_repository.dart';
import 'package:ku_task_management/data/repositories/task_repository.dart';
import 'package:ku_task_management/data/services/widget_task_creation_service.dart';
import 'package:ku_task_management/presentation/screens/task/widget_task_create_screen.dart';

void main() {
  final now = DateTime(2026, 11, 12, 10, 25);
  late AppDatabase db;
  late DriftTaskRepository tasks;
  late DriftTagRepository tags;
  late DriftFolderRepository lists;
  late bool saved;
  late bool cancelled;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    tasks = DriftTaskRepository(database: db);
    tags = DriftTagRepository(database: db);
    lists = DriftFolderRepository(database: db);
    await lists.createFolder(
      Folder(
        id: 'course',
        name: '운영체제',
        color: '#3B82F6',
        createdAt: now,
        updatedAt: now,
      ),
    );
    saved = false;
    cancelled = false;
    await tags.createTag(
      Tag(
        id: 'tag-1',
        name: '졸업프로젝트',
        color: '#22C55E',
        createdAt: now,
        updatedAt: now,
      ),
    );
  });
  tearDown(() => db.close());

  Future<void> open(
    WidgetTester tester, {
    TaskRepository? repository,
    FolderRepository? folderRepository,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: WidgetTaskCreateScreen(
          saveTask: WidgetTaskCreationService(
            database: db,
            taskRepository: repository ?? tasks,
            tagRepository: tags,
          ).save,
          folderRepository: folderRepository ?? lists,
          now: () => now,
          onSaved: () async {
            saved = true;
          },
          onCancel: () {
            cancelled = true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) async {
    await tester.ensureVisible(find.text('저장'));
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
  }

  testWidgets('selects one list without tag or list creation controls', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('태그'), findsNothing);
    expect(find.byTooltip('태그 추가'), findsNothing);
    expect(find.byTooltip('목록 추가'), findsNothing);
    await tester.enterText(find.byType(TextFormField), '과제');
    await tester.tap(find.widgetWithText(FilterChip, '운영체제'));
    await save(tester);
    final task = (await tasks.getTasks()).single;
    expect(task.listId, 'course');
    expect(task.tagIds, isEmpty);
    expect(await tags.getTags(), hasLength(1));
    expect(task.origin, TaskOrigin.personal);
    expect(saved, isTrue);
  });

  testWidgets('list loading failure can retry without losing title', (
    tester,
  ) async {
    final repository = _FailingLists(lists);
    await open(tester, folderRepository: repository);
    await tester.enterText(find.byType(TextFormField), '입력 유지');
    expect(find.textContaining('목록을 불러오지 못했습니다.'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    repository.fail = false;
    await tester.tap(find.text('목록 다시 불러오기'));
    await tester.pumpAndSettle();
    expect(find.text('입력 유지'), findsOneWidget);
    await save(tester);
    expect((await tasks.getTasks()).single.listId, inboxListId);
  });

  testWidgets('rapid save taps create exactly one task', (tester) async {
    final blocking = _BlockingRepository(tasks);
    await open(tester, repository: blocking);
    await tester.enterText(find.byType(TextFormField), '한 번만 저장');
    await tester.ensureVisible(find.text('저장'));
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(blocking.calls, 1);
    expect(saved, isFalse);
    blocking.ready.complete();
    await tester.pumpAndSettle();
    expect(await tasks.getTasks(), hasLength(1));
    expect(saved, isTrue);
  });

  testWidgets('rejects blank title without saving', (tester) async {
    await open(tester);
    await tester.enterText(find.byType(TextFormField), '   ');
    await save(tester);
    expect(find.text('제목을 입력해주세요.'), findsOneWidget);
    expect(await tasks.getTasks(), isEmpty);
    expect(saved, isFalse);
  });

  testWidgets(
    'defaults to Inbox and preserves current minute and optional fields',
    (tester) async {
      await open(tester);
      await tester.enterText(find.byType(TextFormField), '태그 없는 일정');
      await save(tester);
      final task = (await tasks.getTasks()).single;
      expect(task.dueDate, now);
      expect(task.tagIds, isEmpty);
      expect(task.priority, isNull);
      expect(task.memo, isNull);
      expect(task.folderIds, [inboxListId]);
    },
  );

  testWidgets('date and time pickers update persisted deadline', (
    tester,
  ) async {
    await open(tester);
    await tester.enterText(find.byType(TextFormField), '날짜 변경');
    await tester.tap(find.text('마감 날짜  2026.11.12'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('20'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('마감 날짜  2026.11.20'), findsOneWidget);
    await tester.tap(find.text('마감 시간  10:25'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.keyboard_outlined));
    await tester.pumpAndSettle();
    final inputs = find.descendant(
      of: find.byType(TimePickerDialog),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(inputs.at(0), '9');
    await tester.enterText(inputs.at(1), '45');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await save(tester);
    expect(
      (await tasks.getTasks()).single.dueDate,
      DateTime(2026, 11, 20, 9, 45),
    );
  });

  testWidgets('cancel and back do not persist draft', (tester) async {
    await open(tester);
    await tester.enterText(find.byType(TextFormField), '취소할 일정');
    await tester.tap(find.text('취소'));
    await tester.pump();
    expect(cancelled, isTrue);
    expect(await tasks.getTasks(), isEmpty);
    cancelled = false;
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(cancelled, isTrue);
    expect(saved, isFalse);
  });

  testWidgets(
    'DB failure preserves title and selected list and permits retry',
    (tester) async {
      final failing = _FailingRepository(tasks);
      await open(tester, repository: failing);
      await tester.enterText(find.byType(TextFormField), '재시도 일정');
      await tester.tap(find.widgetWithText(FilterChip, '운영체제'));
      await save(tester);
      expect(find.textContaining('일정을 저장하지 못했습니다.'), findsOneWidget);
      expect(find.text('재시도 일정'), findsOneWidget);
      expect(
        tester
            .widget<FilterChip>(find.widgetWithText(FilterChip, '운영체제'))
            .selected,
        isTrue,
      );
      expect(await tasks.getTasks(), isEmpty);
      expect(saved, isFalse);
      failing.fail = false;
      await save(tester);
      expect((await tasks.getTasks()).single.listId, 'course');
      expect(saved, isTrue);
    },
  );
}

class _FailingRepository extends Fake implements TaskRepository {
  _FailingRepository(this.delegate);
  final TaskRepository delegate;
  bool fail = true;
  @override
  Future<Task> createTask(Task task) {
    if (fail) throw StateError('injected DB write failure');
    return delegate.createTask(task);
  }
}

class _BlockingRepository extends Fake implements TaskRepository {
  _BlockingRepository(this.delegate);
  final TaskRepository delegate;
  final ready = Completer<void>();
  int calls = 0;
  @override
  Future<Task> createTask(Task task) async {
    calls++;
    await ready.future;
    return delegate.createTask(task);
  }
}

class _FailingLists extends Fake implements FolderRepository {
  _FailingLists(this.delegate);
  final FolderRepository delegate;
  bool fail = true;
  @override
  Future<List<Folder>> getFolders() {
    if (fail) throw StateError('injected load failure');
    return delegate.getFolders();
  }
}
