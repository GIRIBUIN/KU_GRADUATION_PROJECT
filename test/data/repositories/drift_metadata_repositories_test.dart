import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ku_task_management/data/local/app_database.dart'
    show AppDatabase, TaskFoldersCompanion, TaskTagsCompanion, TasksCompanion;
import 'package:ku_task_management/data/models/task_models.dart';
import 'package:ku_task_management/data/repositories/drift_folder_repository.dart';
import 'package:ku_task_management/data/repositories/drift_notification_repository.dart';
import 'package:ku_task_management/data/repositories/drift_settings_repository.dart';
import 'package:ku_task_management/data/repositories/drift_tag_repository.dart';
import 'package:ku_task_management/data/repositories/settings_repository.dart';

void main() {
  late AppDatabase database;
  late DriftTagRepository tagRepository;
  late DriftFolderRepository folderRepository;
  late DriftNotificationRepository notificationRepository;
  late DriftSettingsRepository settingsRepository;

  final now = DateTime(2026, 5, 7, 10);

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    tagRepository = DriftTagRepository(database: database);
    folderRepository = DriftFolderRepository(database: database);
    notificationRepository = DriftNotificationRepository(database: database);
    settingsRepository = DriftSettingsRepository(database: database);

    await database
        .into(database.tasks)
        .insert(
          TasksCompanion.insert(
            id: 'task-1',
            origin: TaskOrigin.ecampus.name,
            status: TaskStatus.active.name,
            title: '자료구조 과제',
            createdAt: now,
            updatedAt: now,
          ),
        );
  });

  tearDown(() async {
    await database.close();
  });

  group('DriftTagRepository', () {
    test('creates, updates, lists, and deletes tags with relations', () async {
      final tag = _tag(id: 'tag-1', name: '전공');

      await tagRepository.createTag(tag);
      await database
          .into(database.taskTags)
          .insert(TaskTagsCompanion.insert(taskId: 'task-1', tagId: 'tag-1'));

      final updated = await tagRepository.updateTag(
        _tag(id: 'tag-1', name: '전공 필수'),
      );
      final tags = await tagRepository.getTags();

      expect(updated.name, '전공 필수');
      expect(tags.map((tag) => tag.id), ['tag-1']);

      await tagRepository.deleteTag('tag-1');

      expect(await tagRepository.getTagById('tag-1'), isNull);
      expect(await database.select(database.taskTags).get(), isEmpty);
    });
  });

  group('DriftFolderRepository', () {
    test(
      'creates, updates, lists, and deletes folders with relations',
      () async {
        final folder = _folder(id: 'folder-1', name: '이번 주');

        await folderRepository.createFolder(folder);
        await database
            .into(database.taskFolders)
            .insert(
              TaskFoldersCompanion.insert(
                taskId: 'task-1',
                folderId: 'folder-1',
              ),
            );

        final updated = await folderRepository.updateFolder(
          _folder(id: 'folder-1', name: '이번 주 집중'),
        );
        final folders = await folderRepository.getFolders();

        expect(updated.name, '이번 주 집중');
        expect(folders.map((folder) => folder.id), ['folder-1']);

        await folderRepository.deleteFolder('folder-1');

        expect(await folderRepository.getFolderById('folder-1'), isNull);
        expect(await database.select(database.taskFolders).get(), isEmpty);
      },
    );
  });

  group('DriftNotificationRepository', () {
    test('saves one notification per task and deletes by taskId', () async {
      await notificationRepository.save(_notification(id: 'notification-1'));
      final updated = await notificationRepository.save(
        _notification(id: 'notification-2', daysBeforeDue: 3),
      );

      expect(updated.id, 'notification-2');
      expect(updated.daysBeforeDue, 3);
      expect(
        (await database.select(database.notificationSettings).get()).length,
        1,
      );

      await notificationRepository.deleteByTaskId('task-1');

      expect(await notificationRepository.getByTaskId('task-1'), isNull);
    });

    test('lists saved notifications for restart rescheduling', () async {
      await database
          .into(database.tasks)
          .insert(
            TasksCompanion.insert(
              id: 'task-2',
              origin: TaskOrigin.personal.name,
              status: TaskStatus.active.name,
              title: '운영체제 과제',
              createdAt: now,
              updatedAt: now,
            ),
          );

      await notificationRepository.save(_notification(id: 'notification-1'));
      await notificationRepository.save(
        _notification(
          id: 'notification-2',
          taskId: 'task-2',
          daysBeforeDue: 30,
        ),
      );

      final notifications = await notificationRepository.getAll();

      expect(notifications.map((notification) => notification.taskId), [
        'task-1',
        'task-2',
      ]);
    });
  });

  group('DriftSettingsRepository', () {
    test('returns defaults and saves settings as key value rows', () async {
      final defaults = await settingsRepository.getSettings();

      expect(defaults.autoSyncEnabled, isFalse);
      expect(defaults.saveEcampusAccount, isFalse);
      expect(defaults.defaultNotificationEnabled, isTrue);
      expect(defaults.defaultNotificationDays, 60);
      expect(defaults.defaultNotificationTime, 'relative');
      expect(defaults.urgentDueDays, 3);

      final saved = await settingsRepository.saveSettings(
        const AppSettings(
          autoSyncEnabled: false,
          saveEcampusAccount: false,
          defaultNotificationEnabled: false,
          defaultNotificationDays: 180,
          defaultNotificationTime: 'relative',
          urgentDueDays: 7,
        ),
      );

      expect(saved.autoSyncEnabled, isFalse);
      expect(saved.saveEcampusAccount, isFalse);
      expect(saved.defaultNotificationEnabled, isFalse);
      expect(saved.defaultNotificationDays, 180);
      expect(saved.defaultNotificationTime, 'relative');
      expect(saved.urgentDueDays, 7);
      expect((await database.select(database.appSettings).get()).length, 6);

      final restartedRepository = DriftSettingsRepository(database: database);
      final persisted = await restartedRepository.getSettings();

      expect(persisted.autoSyncEnabled, isFalse);
      expect(persisted.saveEcampusAccount, isFalse);
      expect(persisted.defaultNotificationEnabled, isFalse);
      expect(persisted.defaultNotificationDays, 180);
      expect(persisted.defaultNotificationTime, 'relative');
      expect(persisted.urgentDueDays, 7);
    });
  });
}

Tag _tag({required String id, required String name}) {
  final now = DateTime(2026, 5, 7, 10);

  return Tag(
    id: id,
    name: name,
    color: '#1262D6',
    createdAt: now,
    updatedAt: now,
  );
}

Folder _folder({required String id, required String name}) {
  final now = DateTime(2026, 5, 7, 10);

  return Folder(
    id: id,
    name: name,
    color: '#139A50',
    icon: 'folder',
    createdAt: now,
    updatedAt: now,
  );
}

NotificationSetting _notification({
  required String id,
  String taskId = 'task-1',
  int daysBeforeDue = 1,
}) {
  return NotificationSetting(
    id: id,
    taskId: taskId,
    enabled: true,
    daysBeforeDue: daysBeforeDue,
    notifyTime: 'relative',
    scheduledAt: DateTime(2026, 5, 19, 9),
  );
}
