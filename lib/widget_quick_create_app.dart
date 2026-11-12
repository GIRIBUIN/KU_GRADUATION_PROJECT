import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'data/local/app_database.dart';
import 'data/repositories/drift_settings_repository.dart';
import 'data/repositories/drift_tag_repository.dart';
import 'data/repositories/drift_task_repository.dart';
import 'data/services/widget_update_service.dart';
import 'data/services/widget_task_creation_service.dart';
import 'presentation/screens/task/widget_task_create_screen.dart';

/// 메인 화면 대신 등록 팝업만 구성하는 전용 Flutter 앱.
class WidgetQuickCreateApp extends StatefulWidget {
  const WidgetQuickCreateApp({super.key});

  @override
  State<WidgetQuickCreateApp> createState() => _WidgetQuickCreateAppState();
}

class _WidgetQuickCreateAppState extends State<WidgetQuickCreateApp> {
  static const _channel = MethodChannel('ku_todo/widget_quick_create');
  late final AppDatabase _database;
  late final DriftTaskRepository _tasks;
  late final DriftTagRepository _tags;
  late final WidgetUpdateService _widgets;

  @override
  void initState() {
    super.initState();
    // 일반 앱과 동일한 DB와 Repository를 사용해 등록한 일정을 공유한다.
    _database = AppDatabase.defaults();
    _tasks = DriftTaskRepository(database: _database);
    _tags = DriftTagRepository(database: _database);
    _widgets = WidgetUpdateService(
      taskRepository: _tasks,
      settingsRepository: DriftSettingsRepository(database: _database),
      tagRepository: _tags,
    );
  }

  @override
  void dispose() {
    _database.close();
    super.dispose();
  }

  Future<void> _saved() async {
    // 메인 앱이 다시 활성화될 때 목록을 읽도록 알리고, 홈 위젯도 즉시 갱신한다.
    try {
      await _channel.invokeMethod<void>('saved');
      await _widgets.refresh();
    } catch (error, stack) {
      // 일정은 이미 저장됐으므로 재등록하지 않고 다음 앱 실행 시 갱신하도록 한다.
      debugPrint('Quick-create widget refresh failed: $error\n$stack');
    } finally {
      // 저장에 성공한 팝업은 위젯 갱신 성공 여부와 관계없이 종료한다.
      await _channel.invokeMethod<void>('close');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '빠른 일정 등록',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [Locale('ko', 'KR'), Locale('en', 'US')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: WidgetTaskCreateScreen(
        saveTask: WidgetTaskCreationService(
          database: _database,
          taskRepository: _tasks,
          tagRepository: _tags,
        ).save,
        tagRepository: _tags,
        onSaved: _saved,
        onCancel: () {
          _channel.invokeMethod<void>('close');
        },
      ),
    );
  }
}
