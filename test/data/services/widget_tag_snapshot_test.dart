import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ku_task_management/data/local/app_database.dart'
    show AppDatabase;
import 'package:ku_task_management/data/models/task_models.dart';
import 'package:ku_task_management/data/repositories/drift_settings_repository.dart';
import 'package:ku_task_management/data/repositories/drift_tag_repository.dart';
import 'package:ku_task_management/data/repositories/drift_task_repository.dart';
import 'package:ku_task_management/data/services/personal_task_draft.dart';
import 'package:ku_task_management/data/services/widget_update_service.dart';

void main() {
  test(
    'weekly snapshot follows tag edits and deletion; today retains its layout data',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final now = DateTime(2026, 11, 12, 10);
      final tasks = DriftTaskRepository(database: db);
      final tags = DriftTagRepository(database: db);
      final service = WidgetUpdateService(
        taskRepository: tasks,
        settingsRepository: DriftSettingsRepository(database: db),
        tagRepository: tags,
        now: () => now,
      );
      await tags.createTag(
        Tag(
          id: 'tag',
          name: '전공',
          color: '#22C55E',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await tasks.createTask(
        personalTaskDraft(
          title: '새 일정',
          dueDate: now,
          now: now,
          tagIds: ['tag'],
        ),
      );
      var weekly = await service.buildWeeklyWidgetData();
      expect(weekly.tasks.single.categoryLabel, '전공');
      expect(weekly.tasks.single.categoryBackgroundHex, '#22C55E');
      expect(weekly.tasks.single.categoryTextHex, '#000000');
      expect(
        (await service.buildTodayWidgetData()).tasks.single.accentColorHex,
        '#22C55E',
      );
      await tags.updateTag(
        Tag(
          id: 'tag',
          name: '이름 변경',
          color: '#000000',
          createdAt: now,
          updatedAt: now,
        ),
      );
      weekly = await service.buildWeeklyWidgetData();
      expect(weekly.tasks.single.categoryLabel, '이름 변경');
      expect(weekly.tasks.single.categoryBackgroundHex, '#000000');
      expect(weekly.tasks.single.categoryTextHex, '#FFFFFF');
      await tags.deleteTag('tag');
      weekly = await service.buildWeeklyWidgetData();
      expect(weekly.tasks.single.categoryLabel, isEmpty);
      expect((await tasks.getTasks()).single.tagIds, isEmpty);
    },
  );
}
