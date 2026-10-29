import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ku_task_management/data/local/app_database.dart' as db;
import 'package:ku_task_management/data/models/ecampus_models.dart';
import 'package:ku_task_management/data/models/task_models.dart';
import 'package:ku_task_management/data/repositories/drift_folder_repository.dart';
import 'package:ku_task_management/data/repositories/drift_notification_repository.dart';
import 'package:ku_task_management/data/repositories/drift_settings_repository.dart';
import 'package:ku_task_management/data/repositories/drift_sub_task_repository.dart';
import 'package:ku_task_management/data/repositories/drift_tag_repository.dart';
import 'package:ku_task_management/data/repositories/drift_task_repository.dart';
import 'package:ku_task_management/data/repositories/notification_repository.dart';
import 'package:ku_task_management/data/services/ecampus_auth_service.dart';
import 'package:ku_task_management/data/services/ecampus_sync_apply_service.dart';
import 'package:ku_task_management/data/services/ecampus_sync_flow_service.dart';
import 'package:ku_task_management/data/services/ecampus_sync_service.dart';
import 'package:ku_task_management/presentation/screens/sync/ecampus_sync_preview_screen.dart';
import 'package:ku_task_management/presentation/screens/task/task_create_screen.dart';
import 'package:ku_task_management/presentation/services/local_notification_service.dart';

void main() {
  testWidgets(
    'a failed reminder write rolls task creation back and unlocks save',
    (tester) async {
      final database = db.AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final tasks = DriftTaskRepository(database: database);
      await tester.binding.setSurfaceSize(const Size(900, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => TaskCreateScreen(
                      taskRepository: tasks,
                      subTaskRepository: DriftSubTaskRepository(
                        database: database,
                      ),
                      notificationRepository: _FailingReminder(),
                      settingsRepository: DriftSettingsRepository(
                        database: database,
                      ),
                      tagRepository: DriftTagRepository(database: database),
                      folderRepository: DriftFolderRepository(
                        database: database,
                      ),
                      localNotificationService: _Notifications(),
                    ),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Should roll back');
      await tester.tap(find.text('저장').first);
      await tester.pumpAndSettle();
      expect(await tasks.getTasks(includeArchived: true), isEmpty);
      expect(find.textContaining('저장하지 못했습니다'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('task creation persists one folder and independent global tag', (
    tester,
  ) async {
    final database = db.AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final folders = DriftFolderRepository(database: database);
    final tags = DriftTagRepository(database: database);
    final settings = DriftSettingsRepository(database: database);
    final tasks = DriftTaskRepository(database: database);
    final now = DateTime.now();
    await folders.createFolder(
      Folder(id: 'folder', name: 'My folder', createdAt: now, updatedAt: now),
    );
    await tags.createTag(
      Tag(
        id: 'tag',
        name: 'Shared tag',
        color: '#123456',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await settings.saveSettings(
      (await settings.getSettings()).copyWith(
        defaultNotificationEnabled: false,
      ),
    );
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => TaskCreateScreen(
                    taskRepository: tasks,
                    subTaskRepository: DriftSubTaskRepository(
                      database: database,
                    ),
                    notificationRepository: DriftNotificationRepository(
                      database: database,
                    ),
                    settingsRepository: settings,
                    tagRepository: tags,
                    folderRepository: folders,
                    localNotificationService: _Notifications(),
                  ),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'New task');
    await tester.tap(find.text('My folder'));
    await tester.tap(find.text('Shared tag'));
    await tester.tap(find.text('저장').first);
    await tester.pumpAndSettle();
    final saved = (await tasks.getTasks()).single;
    expect(saved.folderIds, ['folder']);
    expect(saved.tagIds, ['tag']);
    expect((await settings.getSettings()).tagFolderIds, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('review applies only the checked source field and keeps memo', (
    tester,
  ) async {
    final database = db.AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final tasks = DriftTaskRepository(database: database);
    final now = DateTime.now();
    final old = await tasks.createTask(
      Task(
        id: 'task',
        origin: TaskOrigin.ecampus,
        status: TaskStatus.active,
        title: 'My title',
        memo: 'My memo',
        createdAt: now,
        updatedAt: now,
        ecampus: const EcampusSyncMetadata(
          sourceKey: 'c:1:report',
          sourceTitle: 'Old source',
        ),
      ),
    );
    final deadline = DateTime(2027, 1, 2, 18);
    final change = SyncItem(
      kind: SyncItemKind.updateCandidate,
      existingTask: old,
      parsedTask: ParsedEcampusTask(
        sourceKey: 'c:1:report',
        title: 'New source',
        course: 'Course',
        type: EcampusTaskType.report,
        dueDate: deadline,
      ),
    );
    final flow = DefaultEcampusSyncFlowService(
      taskRepository: tasks,
      syncService: _NoFetch(),
      applyService: DefaultEcampusSyncApplyService(
        taskRepository: tasks,
        tagRepository: DriftTagRepository(database: database),
        folderRepository: DriftFolderRepository(database: database),
        settingsRepository: DriftSettingsRepository(database: database),
      ),
    );
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: EcampusSyncPreviewScreen(
          syncResult: SyncResult(items: [change], syncedAt: now),
          syncFlowService: flow,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect((await tasks.getTaskById('task'))!.title, 'My title');
    await tester.ensureVisible(find.text('원본 마감일로 변경'));
    await tester.tap(find.text('원본 마감일로 변경'));
    await tester.pump();
    await tester.tap(find.text('가져오기 (1)'));
    await tester.pumpAndSettle();
    final saved = (await tasks.getTaskById('task'))!;
    expect(saved.title, 'My title');
    expect(saved.memo, 'My memo');
    expect(saved.dueDate, deadline);
    expect(saved.ecampus!.sourceTitle, 'New source');
    expect(tester.takeException(), isNull);
  });
}

class _Notifications extends LocalNotificationService {
  @override
  Future<void> scheduleTaskNotification({
    required Task task,
    required NotificationSetting setting,
    bool requestPermissionBeforeScheduling = false,
  }) async {}
}

class _NoFetch implements EcampusSyncService {
  @override
  Future<SyncResult> previewSync({
    required EcampusSession session,
    required List<Task> existingTasks,
    DateTime? syncedAt,
  }) => throw UnsupportedError('Review-only fixture');
}

class _FailingReminder implements NotificationRepository {
  @override
  Future<NotificationSetting?> getByTaskId(String id) async => null;
  @override
  Future<List<NotificationSetting>> getAll() async => [];
  @override
  Future<NotificationSetting> save(NotificationSetting setting) async =>
      throw StateError('fixture write failure');
  @override
  Future<void> deleteByTaskId(String id) async {}
}
