import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'data/local/app_database.dart';
import 'data/models/task_models.dart';
import 'data/repositories/drift_folder_repository.dart';
import 'data/repositories/drift_notification_repository.dart';
import 'data/repositories/drift_settings_repository.dart';
import 'data/repositories/drift_sub_task_repository.dart';
import 'data/repositories/drift_tag_repository.dart';
import 'data/repositories/drift_task_repository.dart';
import 'presentation/screens/main/main_shell_screen.dart';
import 'presentation/services/local_notification_service.dart';

class KuTaskApp extends StatefulWidget {
  const KuTaskApp({super.key});

  @override
  State<KuTaskApp> createState() => _KuTaskAppState();
}

class _KuTaskAppState extends State<KuTaskApp> {
  late final AppDatabase _database;
  late final DriftTaskRepository _taskRepository;
  late final DriftSubTaskRepository _subTaskRepository;
  late final DriftNotificationRepository _notificationRepository;
  late final DriftSettingsRepository _settingsRepository;
  late final DriftTagRepository _tagRepository;
  late final DriftFolderRepository _folderRepository;
  late final LocalNotificationService _localNotificationService;

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
    _rescheduleNotificationsAfterRestart();
  }

  @override
  void dispose() {
    _database.close();
    super.dispose();
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
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: MainShellScreen(
        taskRepository: _taskRepository,
        subTaskRepository: _subTaskRepository,
        notificationRepository: _notificationRepository,
        settingsRepository: _settingsRepository,
        tagRepository: _tagRepository,
        folderRepository: _folderRepository,
        localNotificationService: _localNotificationService,
      ),
    );
  }
}
