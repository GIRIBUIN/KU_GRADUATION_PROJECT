import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'data/local/app_database.dart';
import 'data/repositories/drift_notification_repository.dart';
import 'data/repositories/drift_settings_repository.dart';
import 'data/repositories/drift_sub_task_repository.dart';
import 'data/repositories/drift_task_repository.dart';
import 'presentation/screens/main/main_shell_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _database = AppDatabase.defaults();
    _taskRepository = DriftTaskRepository(database: _database);
    _subTaskRepository = DriftSubTaskRepository(database: _database);
    _notificationRepository = DriftNotificationRepository(database: _database);
    _settingsRepository = DriftSettingsRepository(database: _database);
  }

  @override
  void dispose() {
    _database.close();
    super.dispose();
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
      ),
    );
  }
}
