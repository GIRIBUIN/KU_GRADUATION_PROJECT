import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ku_task_management/data/local/app_database.dart'
    show AppDatabase;
import 'package:ku_task_management/data/models/today_widget_data.dart';
import 'package:ku_task_management/data/models/weekly_widget_data.dart';
import 'package:ku_task_management/data/repositories/drift_settings_repository.dart';
import 'package:ku_task_management/data/repositories/drift_tag_repository.dart';
import 'package:ku_task_management/data/repositories/drift_task_repository.dart';
import 'package:ku_task_management/data/services/personal_task_draft.dart';
import 'package:ku_task_management/data/services/widget_task_creation_service.dart';
import 'package:ku_task_management/data/services/widget_update_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 11, 12, 10);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late AppDatabase db;
  late DriftTaskRepository tasks;
  late WidgetTaskCreationService creator;
  late WidgetUpdateService widgets;
  late Map<String, Object?> storage;
  late List<String> updates;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    tasks = DriftTaskRepository(database: db);
    final tags = DriftTagRepository(database: db);
    creator = WidgetTaskCreationService(
      database: db,
      taskRepository: tasks,
      tagRepository: tags,
    );
    widgets = WidgetUpdateService(
      taskRepository: tasks,
      tagRepository: tags,
      settingsRepository: DriftSettingsRepository(database: db),
      now: () => now,
    );
    // Existing native widget pages must survive a full data refresh.
    storage = {
      'widget_page_101': 1,
      'widget_page_102': 0,
      'widget_page_201': 1,
    };
    updates = [];
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => '/test/documents',
    );
    messenger.setMockMethodCallHandler(const MethodChannel('home_widget'), (
      call,
    ) async {
      final args = call.arguments as Map;
      switch (call.method) {
        case 'getWidgetData':
          return storage[args['id']] ?? args['defaultValue'];
        case 'saveWidgetData':
          storage[args['id'] as String] = args['data'];
          return true;
        case 'updateWidget':
          // Both complete snapshots must be ready before either provider renders.
          expect(storage[TodayWidgetData.storageKey], isNotNull);
          expect(storage[WeeklyWidgetData.storageKey], isNotNull);
          updates.add(args['android'] as String);
          return true;
      }
      return null;
    });
  });
  tearDown(() async {
    messenger.setMockMethodCallHandler(
      const MethodChannel('home_widget'),
      null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    await db.close();
  });

  for (final count in [3, 5, 8]) {
    test(
      'registration after $count tasks refreshes both full lists without resetting pages',
      () async {
        for (var i = 0; i < count; i++) {
          await tasks.createTask(
            personalTaskDraft(
              title: '기존 $i',
              now: now.add(Duration(microseconds: i)),
              dueDate: now.add(Duration(hours: i + 1)),
            ),
          );
        }
        await creator.save(
          personalTaskDraft(
            title: '추가 일정',
            now: now.add(const Duration(seconds: 1)),
            dueDate: now,
          ),
          const [],
        );
        await widgets.refresh();
        final today = TodayWidgetData.fromJson(
          jsonDecode(storage[TodayWidgetData.storageKey] as String),
        );
        final week = WeeklyWidgetData.fromJson(
          jsonDecode(storage[WeeklyWidgetData.storageKey] as String),
        );
        expect(today.tasks, hasLength(count + 1));
        expect(week.tasks, hasLength(count + 1));
        expect(today.tasks.first.title, '추가 일정');
        expect(week.tasks.first.title, '추가 일정');
        expect((today.tasks.length + 2) ~/ 3, (count + 3) ~/ 3);
        expect((week.tasks.length + 4) ~/ 5, (count + 5) ~/ 5);
        expect(updates, [
          'ScheduleWidgetProvider',
          'WeeklyScheduleWidgetProvider',
        ]);
        expect(storage['widget_page_101'], 1);
        expect(storage['widget_page_102'], 0);
        expect(storage['widget_page_201'], 1);
      },
    );
  }

  test(
    'out-of-week registration stays in DB and out of both widget lists',
    () async {
      await creator.save(
        personalTaskDraft(
          title: '다음 주 일정',
          now: now,
          dueDate: DateTime(2026, 11, 17, 18),
        ),
        const [],
      );
      await widgets.refresh();
      expect(await tasks.getTasks(), hasLength(1));
      expect(
        jsonDecode(storage[TodayWidgetData.storageKey] as String)['tasks'],
        isEmpty,
      );
      expect(
        jsonDecode(storage[WeeklyWidgetData.storageKey] as String)['tasks'],
        isEmpty,
      );
      expect(updates, hasLength(2));
    },
  );

  test('weekly-only registration does not appear in today widget', () async {
    await creator.save(
      personalTaskDraft(
        title: '일요일 일정',
        now: now,
        dueDate: DateTime(2026, 11, 15, 18),
      ),
      const [],
    );
    await widgets.refresh();
    expect(
      jsonDecode(storage[TodayWidgetData.storageKey] as String)['tasks'],
      isEmpty,
    );
    expect(
      jsonDecode(storage[WeeklyWidgetData.storageKey] as String)['tasks'],
      hasLength(1),
    );
  });
}
