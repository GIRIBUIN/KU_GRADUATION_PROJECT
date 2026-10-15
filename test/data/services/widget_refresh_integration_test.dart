import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ku_task_management/data/local/app_database.dart';
import 'package:ku_task_management/data/repositories/drift_settings_repository.dart';
import 'package:ku_task_management/data/repositories/drift_tag_repository.dart';
import 'package:ku_task_management/data/repositories/drift_task_repository.dart';
import 'package:ku_task_management/data/services/widget_update_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'app refresh publishes the shared database to all three widgets',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final data = <String, Object?>{};
      final providers = <String>[];
      messenger.setMockMethodCallHandler(const MethodChannel('home_widget'), (
        call,
      ) async {
        final arguments = call.arguments as Map;
        switch (call.method) {
          case 'getWidgetData':
            return data[arguments['id']] ?? arguments['defaultValue'];
          case 'saveWidgetData':
            data[arguments['id'] as String] = arguments['data'];
            return true;
          case 'updateWidget':
            expect(
              data[WidgetUpdateService.widgetDatabasePathKey],
              endsWith('/ku_task_management.sqlite'),
            );
            providers.add(arguments['android'] as String);
            return true;
          default:
            return null;
        }
      });
      messenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (_) async => 'widget-test-documents',
      );
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

      await WidgetUpdateService(
        taskRepository: DriftTaskRepository(database: database),
        settingsRepository: DriftSettingsRepository(database: database),
        tagRepository: DriftTagRepository(database: database),
      ).refresh();

      expect(providers, [
        'ScheduleWidgetProvider',
        'WeeklyScheduleWidgetProvider',
        'CalendarWidgetProvider',
      ]);
    },
  );
}
