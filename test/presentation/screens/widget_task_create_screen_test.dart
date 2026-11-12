import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ku_task_management/data/local/app_database.dart'
    show AppDatabase;
import 'package:ku_task_management/data/models/task_models.dart';
import 'package:ku_task_management/data/repositories/drift_tag_repository.dart';
import 'package:ku_task_management/data/repositories/drift_task_repository.dart';
import 'package:ku_task_management/data/repositories/task_repository.dart';
import 'package:ku_task_management/data/services/widget_task_creation_service.dart';
import 'package:ku_task_management/presentation/screens/task/widget_task_create_screen.dart';

void main() {
  final now = DateTime(2026, 11, 12, 10, 25);
  late AppDatabase db;
  late DriftTaskRepository tasks;
  late DriftTagRepository tags;
  late bool saved;
  late bool cancelled;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    tasks = DriftTaskRepository(database: db);
    tags = DriftTagRepository(database: db);
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

  Future<void> open(WidgetTester tester, {TaskRepository? repository}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: WidgetTaskCreateScreen(
          saveTask: WidgetTaskCreationService(
            database: db,
            taskRepository: repository ?? tasks,
            tagRepository: tags,
          ).save,
          tagRepository: tags,
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

  Future<void> addTag(
    WidgetTester tester,
    String name, {
    String color = '#8B5CF6',
  }) async {
    await tester.tap(find.byTooltip('태그 추가'));
    await tester.pumpAndSettle();
    final inputs = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(inputs.at(0), name);
    await tester.enterText(inputs.at(1), color);
    await tester.tap(
      find.descendant(of: find.byType(AlertDialog), matching: find.text('저장')),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('typed tag name and color are committed with the task', (
    tester,
  ) async {
    await open(tester);
    await tester.enterText(find.byType(TextFormField), '직접 태그 일정');
    await addTag(tester, '  새 태그  ');
    expect((await tags.getTags()).map((tag) => tag.name), ['졸업프로젝트']);
    final chip = find.widgetWithText(FilterChip, '새 태그');
    expect(tester.widget<FilterChip>(chip).selected, isTrue);
    await save(tester);
    final createdTag = (await tags.getTags()).singleWhere(
      (tag) => tag.name == '새 태그',
    );
    expect(createdTag.color, '#8B5CF6');
    expect((await tasks.getTasks()).single.tagIds, [createdTag.id]);
    expect(saved, isTrue);
  });

  testWidgets('cancelling the form does not create typed tags', (tester) async {
    await open(tester);
    await addTag(tester, '취소 태그');
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(cancelled, isTrue);
    expect((await tags.getTags()).map((tag) => tag.name), ['졸업프로젝트']);
    expect(await tasks.getTasks(), isEmpty);
  });

  testWidgets(
    'typing an existing tag selects it without duplicating or recoloring',
    (tester) async {
      await open(tester);
      await tester.enterText(find.byType(TextFormField), '기존 태그');
      await addTag(tester, '졸업프로젝트');
      await save(tester);
      expect(await tags.getTags(), hasLength(1));
      expect((await tags.getTags()).single.color, '#22C55E');
      expect((await tasks.getTasks()).single.tagIds, ['tag-1']);
    },
  );

  testWidgets(
    'DB failure rolls back new tags, preserves input, and retries atomically',
    (tester) async {
      final failing = _FailingRepository(tasks);
      await open(tester, repository: failing);
      await tester.enterText(find.byType(TextFormField), '새 태그 재시도');
      await addTag(tester, '재시도 태그');
      await save(tester);
      expect(await tags.getTags(), hasLength(1));
      expect(await tasks.getTasks(), isEmpty);
      expect(
        tester
            .widget<FilterChip>(find.widgetWithText(FilterChip, '재시도 태그'))
            .selected,
        isTrue,
      );
      expect(find.text('새 태그 재시도'), findsOneWidget);
      failing.fail = false;
      await save(tester);
      expect(await tags.getTags(), hasLength(2));
      final newTag = (await tags.getTags()).singleWhere(
        (tag) => tag.name == '재시도 태그',
      );
      expect((await tasks.getTasks()).single.tagIds, [newTag.id]);
    },
  );

  testWidgets('deselected draft tags are not persisted', (tester) async {
    await open(tester);
    await tester.enterText(find.byType(TextFormField), '선택 해제');
    await addTag(tester, '사용 안 함');
    await tester.tap(find.widgetWithText(FilterChip, '사용 안 함'));
    await save(tester);
    expect(await tags.getTags(), hasLength(1));
    expect((await tasks.getTasks()).single.tagIds, isEmpty);
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
    'uses today/current minute, existing multiple-select tags and standard DB',
    (tester) async {
      await tags.createTag(
        Tag(
          id: 'tag-2',
          name: '전공',
          color: '#3B82F6',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await open(tester);
      expect(find.text('마감 날짜  2026.11.12'), findsOneWidget);
      expect(find.text('마감 시간  10:25'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), '  위젯 일정  ');
      await tester.tap(find.widgetWithText(FilterChip, '졸업프로젝트'));
      await tester.ensureVisible(find.widgetWithText(FilterChip, '전공'));
      await tester.tap(find.widgetWithText(FilterChip, '전공'));
      await save(tester);
      final list = await tasks.getTasks();
      expect(list, hasLength(1));
      expect(list.single.title, '위젯 일정');
      expect(list.single.dueDate, now);
      expect(list.single.tagIds, unorderedEquals(['tag-1', 'tag-2']));
      expect(list.single.origin, TaskOrigin.personal);
      expect(list.single.status, TaskStatus.active);
      expect(list.single.sortOrder, greaterThanOrEqualTo(0));
      expect(saved, isTrue);
    },
  );

  testWidgets('saves without tags with default optional fields', (
    tester,
  ) async {
    await open(tester);
    await tester.enterText(find.byType(TextFormField), '태그 없는 일정');
    await save(tester);
    final task = (await tasks.getTasks()).single;
    expect(task.tagIds, isEmpty);
    expect(task.priority, isNull);
    expect(task.memo, isNull);
    expect(task.folderIds, isEmpty);
  });

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

  testWidgets('DB failure preserves title and selected tag and permits retry', (
    tester,
  ) async {
    final failing = _FailingRepository(tasks);
    await open(tester, repository: failing);
    await tester.enterText(find.byType(TextFormField), '재시도 일정');
    await tester.tap(find.widgetWithText(FilterChip, '졸업프로젝트'));
    await save(tester);
    expect(find.textContaining('일정을 저장하지 못했습니다.'), findsOneWidget);
    expect(find.text('재시도 일정'), findsOneWidget);
    expect(tester.widget<FilterChip>(find.byType(FilterChip)).selected, isTrue);
    expect(await tasks.getTasks(), isEmpty);
    expect(saved, isFalse);
    failing.fail = false;
    await save(tester);
    expect((await tasks.getTasks()).single.tagIds, ['tag-1']);
    expect(saved, isTrue);
  });
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
