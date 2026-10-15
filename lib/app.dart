import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'data/local/app_database.dart';
import 'data/models/task_models.dart';
import 'data/repositories/drift_folder_repository.dart';
import 'data/repositories/drift_notification_repository.dart';
import 'data/repositories/drift_settings_repository.dart';
import 'data/repositories/drift_sub_task_repository.dart';
import 'data/repositories/drift_tag_repository.dart';
import 'data/repositories/drift_task_repository.dart';
import 'data/services/widget_update_service.dart';
import 'presentation/screens/main/main_shell_screen.dart';
import 'presentation/services/local_notification_service.dart';
import 'data/services/apple_widget_bridge.dart';
import 'data/services/widget_workspace_controller.dart';
import 'presentation/widgets/widget_workspace_page.dart';

class KuTaskApp extends StatefulWidget {
  const KuTaskApp({super.key});

  @override
  State<KuTaskApp> createState() => _KuTaskAppState();
}

class _KuTaskAppState extends State<KuTaskApp> {
  final _navigator = GlobalKey<NavigatorState>();
  StreamSubscription<Uri>? _widgetLinks;
  bool _widgetDialogOpen = false;
  late final AppDatabase _database;
  late final DriftTaskRepository _taskRepository;
  late final DriftSubTaskRepository _subTaskRepository;
  late final DriftNotificationRepository _notificationRepository;
  late final DriftSettingsRepository _settingsRepository;
  late final DriftTagRepository _tagRepository;
  late final DriftFolderRepository _folderRepository;
  late final LocalNotificationService _localNotificationService;
  late final WidgetUpdateService _widgetUpdateService;

  @override
  void initState() {
    super.initState();
    _database = AppDatabase.defaults();
    _taskRepository = DriftTaskRepository(database: _database);
    _subTaskRepository = DriftSubTaskRepository(database: _database);
    _notificationRepository = DriftNotificationRepository(database: _database);
    _settingsRepository = DriftSettingsRepository(database: _database);
    _tagRepository = DriftTagRepository(database: _database);
    _folderRepository = DriftFolderRepository(database: _database);
    _localNotificationService = LocalNotificationService();
    _widgetUpdateService = WidgetUpdateService(
      taskRepository: _taskRepository,
      settingsRepository: _settingsRepository,
      tagRepository: _tagRepository,
    );
    _rescheduleNotificationsAfterRestart();
    _widgetUpdateService.refresh();
    _widgetLinks = AppleWidgetBridge.links.listen(_openWidget);
    if (AppleWidgetBridge.initialLink case final Uri uri) {
      AppleWidgetBridge.initialLink = null;
      WidgetsBinding.instance.addPostFrameCallback((_) => _openWidget(uri));
    }
  }

  @override
  void dispose() {
    _widgetLinks?.cancel();
    _database.close();
    super.dispose();
  }

  Future<void> _openWidget(Uri uri) async {
    final context = _navigator.currentContext;
    if (context == null || _widgetDialogOpen || uri.scheme != 'kutodo') return;
    _widgetDialogOpen = true;
    final kind = WidgetKind.values.firstWhere(
      (kind) => kind.name == uri.queryParameters['kind'],
      orElse: () =>
          uri.host == 'calendar' ? WidgetKind.calendar : WidgetKind.today,
    );
    final controller = WidgetWorkspaceController(
      _database,
      kind,
      notifications: _localNotificationService,
    );
    final page = GlobalKey<WidgetWorkspacePageState>();
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => SizedBox.expand(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => page.currentState?.close(),
            child: Center(
              child: GestureDetector(
                onTap: () {},
                child: Dialog(
                  backgroundColor: Colors.transparent,
                  insetPadding: const EdgeInsets.all(24),
                  child: SizedBox(
                    width: 420,
                    height: (MediaQuery.sizeOf(context).height * .62).clamp(
                      200,
                      620,
                    ),
                    child: WidgetWorkspacePage(
                      key: page,
                      controller: controller,
                      initialUri: uri,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } finally {
      _widgetDialogOpen = false;
      controller.dispose();
    }
  }

  Future<void> _rescheduleNotificationsAfterRestart() async {
    final tasks = await _taskRepository.getTasks(includeArchived: true);
    final settings = await _notificationRepository.getAll();
    final tasksById = {for (final task in tasks) task.id: task};

    for (final setting in settings) {
      final task = tasksById[setting.taskId];
      if (task == null || task.status != TaskStatus.active) {
        await _localNotificationService.cancelTaskNotification(setting.taskId);
        continue;
      }

      await _localNotificationService.scheduleTaskNotification(
        task: task,
        setting: setting,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KU Todo',
      navigatorKey: _navigator,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [Locale('ko', 'KR'), Locale('en', 'US')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) => Stack(
        children: [
          Positioned.fill(child: child!),
          if (isDesktopWidgetPlatform)
            Positioned(
              right: 12,
              top: 8,
              child: SafeArea(
                child: Material(
                  color: Colors.transparent,
                  child: PopupMenuButton<WidgetKind>(
                    tooltip: '바탕화면 위젯 열기',
                    icon: const Icon(Icons.widgets_outlined),
                    onSelected: (kind) => launchDesktopWidget(kind),
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: WidgetKind.today,
                        child: Text('오늘 할 일정 위젯'),
                      ),
                      PopupMenuItem(
                        value: WidgetKind.week,
                        child: Text('이번 주 일정 위젯'),
                      ),
                      PopupMenuItem(
                        value: WidgetKind.calendar,
                        child: Text('캘린더 위젯'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      home: MainShellScreen(
        taskRepository: _taskRepository,
        subTaskRepository: _subTaskRepository,
        notificationRepository: _notificationRepository,
        settingsRepository: _settingsRepository,
        tagRepository: _tagRepository,
        folderRepository: _folderRepository,
        localNotificationService: _localNotificationService,
        widgetUpdateService: _widgetUpdateService,
      ),
    );
  }
}
