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
        expect(updated.sortOrder, 0);
        expect(folders.map((folder) => folder.id), ['folder-1']);

        await folderRepository.deleteFolder('folder-1');

        expect(await folderRepository.getFolderById('folder-1'), isNull);
        expect(await database.select(database.taskFolders).get(), isEmpty);
      },
    );

    test('stores folder order within the same parent', () async {
      await folderRepository.createFolder(
        _folder(id: 'folder-1', name: 'B', sortOrder: -1),
      );
      await folderRepository.createFolder(
        _folder(id: 'folder-2', name: 'A', sortOrder: -1),
      );

      expect((await folderRepository.getFolders()).map((folder) => folder.id), [
        'folder-1',
        'folder-2',
      ]);

      await folderRepository.updateFolderOrder(['folder-2', 'folder-1']);

      expect((await folderRepository.getFolders()).map((folder) => folder.id), [
        'folder-2',
        'folder-1',
      ]);
    });
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
      expect(defaults.homeSelectedTagId, isNull);
      expect(defaults.hiddenTagIds, isEmpty);
      expect(defaults.hiddenFolderIds, isEmpty);
      expect(defaults.tagFolderIds, isEmpty);
      expect(defaults.tagSortOrders, isEmpty);
      expect(defaults.ecampusFolderId, isNull);

      final saved = await settingsRepository.saveSettings(
        const AppSettings(
          autoSyncEnabled: false,
          saveEcampusAccount: false,
          defaultNotificationEnabled: false,
          defaultNotificationDays: 180,
          defaultNotificationTime: 'relative',
          urgentDueDays: 7,
          homeSelectedTagId: 'tag-1',
          hiddenTagIds: {'tag-2'},
          hiddenFolderIds: {'folder-1'},
          tagFolderIds: {'tag-2': 'folder-1'},
          tagSortOrders: {'tag-2': 1},
          ecampusFolderId: 'folder-ecampus',
        ),
      );

      expect(saved.autoSyncEnabled, isFalse);
      expect(saved.saveEcampusAccount, isFalse);
      expect(saved.defaultNotificationEnabled, isFalse);
      expect(saved.defaultNotificationDays, 180);
      expect(saved.defaultNotificationTime, 'relative');
      expect(saved.urgentDueDays, 7);
      expect(saved.homeSelectedTagId, 'tag-1');
      expect(saved.hiddenTagIds, {'tag-2'});
      expect(saved.hiddenFolderIds, {'folder-1'});
      expect(saved.tagFolderIds, {'tag-2': 'folder-1'});
      expect(saved.tagSortOrders, {'tag-2': 1});
      expect(saved.ecampusFolderId, 'folder-ecampus');
      expect((await database.select(database.appSettings).get()).length, 12);

      final restartedRepository = DriftSettingsRepository(database: database);
      final persisted = await restartedRepository.getSettings();

      expect(persisted.autoSyncEnabled, isFalse);
      expect(persisted.saveEcampusAccount, isFalse);
      expect(persisted.defaultNotificationEnabled, isFalse);
      expect(persisted.defaultNotificationDays, 180);
      expect(persisted.defaultNotificationTime, 'relative');
      expect(persisted.urgentDueDays, 7);
      expect(persisted.homeSelectedTagId, 'tag-1');
      expect(persisted.hiddenTagIds, {'tag-2'});
      expect(persisted.hiddenFolderIds, {'folder-1'});
      expect(persisted.tagFolderIds, {'tag-2': 'folder-1'});
      expect(persisted.tagSortOrders, {'tag-2': 1});
      expect(persisted.ecampusFolderId, 'folder-ecampus');

      final cleared = await restartedRepository.saveSettings(
        persisted.copyWith(
          homeSelectedTagId: null,
          hiddenTagIds: const <String>{},
          hiddenFolderIds: const <String>{},
          tagFolderIds: const <String, String>{},
          tagSortOrders: const <String, int>{},
          ecampusFolderId: null,
        ),
      );

      expect(cleared.homeSelectedTagId, isNull);
      expect(cleared.hiddenTagIds, isEmpty);
      expect(cleared.hiddenFolderIds, isEmpty);
      expect(cleared.tagFolderIds, isEmpty);
      expect(cleared.tagSortOrders, isEmpty);
      expect(cleared.ecampusFolderId, isNull);
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

Folder _folder({required String id, required String name, int sortOrder = 0}) {
  final now = DateTime(2026, 5, 7, 10);

  return Folder(
    id: id,
    name: name,
    color: '#139A50',
    icon: 'folder',
    sortOrder: sortOrder,
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
