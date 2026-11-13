import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ku_task_management/data/local/app_database.dart'
    show AppDatabase;
import 'package:ku_task_management/data/repositories/drift_task_repository.dart';
import 'package:ku_task_management/data/services/personal_task_draft.dart';
import 'package:ku_task_management/data/services/widget_background_refresh.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final sunday = DateTime(2026, 11, 15, 23, 59);
  final monday = DateTime(2026, 11, 16);

  for (final now in [sunday, monday]) {
    test('headless refresh rebuilds both DB snapshots for $now', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final tasks = DriftTaskRepository(database: db);
      for (final due in [sunday, monday]) {
        await tasks.createTask(
          personalTaskDraft(
            title: due == sunday ? 'Sunday' : 'Monday',
            now: due,
            dueDate: due,
          ),
        );
      }
      final storage = <String, Object?>{
        'schedule_widget_data': '{"tasks":[{"title":"stale"}]}',
        'weekly_schedule_widget_data': '{"tasks":[{"title":"stale"}]}',
        'widget_page_101': 1,
      };
      final updates = <String>[];
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
            updates.add(args['android'] as String);
            return true;
        }
        return null;
      });
      addTearDown(() {
        messenger.setMockMethodCallHandler(
          const MethodChannel('home_widget'),
          null,
        );
        messenger.setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
      });
      // Uses the production background entry's service; no runApp/Activity needed.
      await refreshWidgetsInBackground(now: () => now, openDatabase: () => db);
      for (final key in [
        'schedule_widget_data',
        'weekly_schedule_widget_data',
      ]) {
        final data = jsonDecode(storage[key] as String) as Map;
        expect(
          (data['tasks'] as List).single['title'],
          now == sunday ? 'Sunday' : 'Monday',
        );
        expect(data['updatedAt'], now.toIso8601String());
      }
      expect(updates, [
        'ScheduleWidgetProvider',
        'WeeklyScheduleWidgetProvider',
      ]);
      expect(storage['widget_page_101'], 1);
    });
  }
}
