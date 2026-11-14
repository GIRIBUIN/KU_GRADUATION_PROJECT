import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ku_task_management/core/utils/list_defaults.dart';
import 'package:ku_task_management/data/local/app_database.dart'
    show AppDatabase;
import 'package:ku_task_management/data/models/task_models.dart';
import 'package:ku_task_management/data/repositories/drift_folder_repository.dart';
import 'package:ku_task_management/data/repositories/drift_settings_repository.dart';
import 'package:ku_task_management/data/repositories/drift_tag_repository.dart';
import 'package:ku_task_management/data/repositories/drift_task_repository.dart';
import 'package:ku_task_management/data/services/personal_task_draft.dart';
import 'package:ku_task_management/data/services/widget_update_service.dart';

void main() {
  final now = DateTime(2026, 11, 15, 10);
  late AppDatabase db;
  late DriftFolderRepository lists;
  late DriftTagRepository tags;
  late DriftTaskRepository tasks;
  late WidgetUpdateService widgets;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    lists = DriftFolderRepository(database: db);
    tags = DriftTagRepository(database: db);
    tasks = DriftTaskRepository(database: db);
    widgets = WidgetUpdateService(
      taskRepository: tasks,
      folderRepository: lists,
      settingsRepository: DriftSettingsRepository(database: db),
      now: () => now,
    );
  });
  tearDown(() => db.close());

  test(
    'both widgets follow list edits and moves, independently from tags',
    () async {
      await lists.saveGroup(
        FolderGroup(id: 'school', name: '학교', createdAt: now, updatedAt: now),
      );
      await lists.createFolder(
        Folder(
          id: 'course',
          name: '운영체제',
          groupId: 'school',
          color: '#3B82F6',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await tags.createTag(
        Tag(
          id: 'tag',
          name: '과제',
          color: '#EF4444',
          createdAt: now,
          updatedAt: now,
        ),
      );
      final task = await tasks.createTask(
        personalTaskDraft(
          title: '과제 제출',
          now: now,
          dueDate: now,
          listId: 'course',
          tagIds: ['tag'],
        ),
      );
      var today = (await widgets.buildTodayWidgetData()).tasks.single;
      var weekly = (await widgets.buildWeeklyWidgetData()).tasks.single;
      expect(today.listLabel, '운영체제');
      expect(today.accentColorHex, '#3B82F6');
      expect(weekly.categoryLabel, '운영체제');
      expect(weekly.categoryBackgroundHex, '#3B82F6');
      expect(today.toJson()['listLabel'], '운영체제');

      final list = (await lists.getFolderById('course'))!;
      await lists.updateFolder(
        Folder(
          id: list.id,
          name: '이름 변경',
          groupId: list.groupId,
          color: '#000000',
          sortOrder: list.sortOrder,
          createdAt: list.createdAt,
          updatedAt: now,
        ),
      );
      today = (await widgets.buildTodayWidgetData()).tasks.single;
      weekly = (await widgets.buildWeeklyWidgetData()).tasks.single;
      expect(today.listLabel, '이름 변경');
      expect(today.accentColorHex, '#000000');
      expect(weekly.categoryLabel, '이름 변경');
      expect(weekly.categoryTextHex, '#FFFFFF');

      await tasks.updateTask(
        Task(
          id: task.id,
          origin: task.origin,
          status: task.status,
          title: task.title,
          folderIds: [inboxListId],
          tagIds: task.tagIds,
          dueDate: task.dueDate,
          createdAt: task.createdAt,
          updatedAt: now,
        ),
      );
      expect(
        (await widgets.buildTodayWidgetData()).tasks.single.listLabel,
        isEmpty,
      );
      expect(
        (await widgets.buildWeeklyWidgetData()).tasks.single.categoryLabel,
        isEmpty,
      );
      expect((await tasks.getTaskById(task.id))!.tagIds, ['tag']);
      expect((await tags.getTags()).single.color, '#EF4444');
    },
  );

  test('Inbox and unavailable lists never fall back to tag labels', () async {
    await tags.createTag(
      Tag(
        id: 'tag',
        name: '과제',
        color: '#EF4444',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await tasks.createTask(
      personalTaskDraft(
        title: 'Inbox',
        now: now,
        dueDate: now,
        tagIds: ['tag'],
      ),
    );
    expect(
      (await widgets.buildTodayWidgetData()).tasks.single.listLabel,
      isEmpty,
    );
    expect(
      (await widgets.buildWeeklyWidgetData()).tasks.single.categoryLabel,
      isEmpty,
    );
    await lists.createFolder(
      Folder(id: 'removed', name: '숨길 소속', createdAt: now, updatedAt: now),
    );
    await tasks.createTask(
      personalTaskDraft(
        title: '삭제된 목록',
        now: now.add(const Duration(seconds: 1)),
        dueDate: now,
        listId: 'removed',
        tagIds: ['tag'],
      ),
    );
    await lists.deleteFolder('removed');
    expect(
      (await widgets.buildWeeklyWidgetData()).tasks.map((t) => t.categoryLabel),
      everyElement(isEmpty),
    );
    expect(
      (await widgets.buildTodayWidgetData()).tasks.map((t) => t.listLabel),
      everyElement(isEmpty),
    );
  });
}
