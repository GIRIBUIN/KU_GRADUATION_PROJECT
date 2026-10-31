import 'package:drift/drift.dart' show Value;
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ku_task_management/data/local/app_database.dart'
    show AppDatabase, TaskTagsCompanion, TasksCompanion;
import 'package:ku_task_management/data/models/task_models.dart';
import 'package:ku_task_management/data/models/task_swipe_options.dart';
import 'package:ku_task_management/data/models/home_section.dart';
import 'package:ku_task_management/data/models/home_view_options.dart';
import 'package:ku_task_management/data/models/home_period_preference.dart';
import 'package:ku_task_management/data/local/mappers/metadata_mappers.dart';
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
          .insert(
            TaskTagsCompanion.insert(
              taskId: 'task-1',
              tagId: 'tag-1',
              updatedAt: now,
            ),
          );

      final updated = await tagRepository.updateTag(
        _tag(id: 'tag-1', name: '전공 필수'),
      );
      final tags = await tagRepository.getTags();

      expect(updated.name, '전공 필수');
      expect(tags.map((tag) => tag.id), ['tag-1']);

      await tagRepository.deleteTag('tag-1');

      expect(await tagRepository.getTagById('tag-1'), isNull);
      expect(
        await (database.select(
          database.taskTags,
        )..where((t) => t.deletedAt.isNull())).get(),
        isEmpty,
      );
    });
  });

  group('DriftFolderRepository', () {
    test(
      'creates, updates, lists, and deletes folders with relations',
      () async {
        final folder = _folder(id: 'folder-1', name: '이번 주');

        await folderRepository.createFolder(folder);
        await (database.update(database.tasks)
              ..where((t) => t.id.equals('task-1')))
            .write(const TasksCompanion(folderId: Value('folder-1')));

        final updated = await folderRepository.updateFolder(
          _folder(id: 'folder-1', name: '이번 주 집중'),
        );
        final folders = await folderRepository.getFolders();

        expect(updated.name, '이번 주 집중');
        expect(updated.sortOrder, 0);
        expect(folders.map((folder) => folder.id), [
          'kutodo:inbox',
          'folder-1',
        ]);

        await folderRepository.deleteFolder('folder-1');

        expect(
          (await folderRepository.getFolderById('folder-1'))!.archivedAt,
          isNotNull,
        );
        expect(
          (await database.select(database.tasks).get()).single.folderId,
          'folder-1',
        );
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
        'kutodo:inbox',
        'folder-1',
        'folder-2',
      ]);

      await folderRepository.updateFolderOrder(['folder-2', 'folder-1']);

      expect((await folderRepository.getFolders()).map((folder) => folder.id), [
        'kutodo:inbox',
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
      expect((await database.select(database.taskReminders).get()).length, 1);

      await notificationRepository.deleteByTaskId('task-1');

      expect(await notificationRepository.getByTaskId('task-1'), isNull);
    });

    test('lists saved notifications for restart rescheduling', () async {
      await database
          .into(database.tasks)
          .insert(
            TasksCompanion.insert(
              id: 'task-2',
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
    test(
      'reading settings does not restore or convert old deleted lists',
      () async {
        final now = DateTime.now();
        await folderRepository.createFolder(
          Folder(id: 'old-list', name: '이전 목록', createdAt: now, updatedAt: now),
        );
        await folderRepository.deleteFolder('old-list');
        final before = (await folderRepository.getFolderById('old-list'))!;
        final settings = await settingsRepository.getSettings();
        final after = (await folderRepository.getFolderById('old-list'))!;
        expect(after.archivedAt, before.archivedAt);
        expect(after.archivedAt, isNotNull);
        expect(after.updatedAt, before.updatedAt);
        expect(settings.hiddenFolderIds.contains('old-list'), isFalse);
        expect(
          (await folderRepository.getFolders()).any(
            (list) => list.id == 'old-list',
          ),
          isFalse,
        );
      },
    );

    test('returns defaults and saves settings as key value rows', () async {
      final defaults = await settingsRepository.getSettings();

      expect(defaults.autoSyncEnabled, isFalse);
      expect(defaults.saveEcampusAccount, isFalse);
      expect(defaults.defaultNotificationEnabled, isTrue);
      expect(defaults.defaultNotificationDays, 60);
      expect(defaults.defaultNotificationTime, 'relative');
      expect(defaults.urgentDueDays, 3);
      expect(defaults.homeSelectedTagId, isNull);
      expect(defaults.homeSectionOrder, HomeSection.values);
      expect(defaults.hiddenHomeSections, {HomeSection.calendar});
      expect(defaults.hiddenTagIds, isEmpty);
      expect(defaults.hiddenFolderIds, isEmpty);
      expect(defaults.tagFolderIds, isEmpty);
      expect(defaults.tagSortOrders, isEmpty);
      expect(defaults.ecampusFolderId, isNull);

      await tagRepository.createTag(_tag(id: 'tag-2', name: 'Global'));
      final saved = await settingsRepository.saveSettings(
        const AppSettings(
          autoSyncEnabled: false,
          saveEcampusAccount: false,
          defaultNotificationEnabled: false,
          defaultNotificationDays: 180,
          defaultNotificationTime: 'relative',
          urgentDueDays: 7,
          homeSelectedTagId: 'tag-1',
          homeSectionOrder: [
            HomeSection.calendar,
            HomeSection.overdueTasks,
            HomeSection.todayTasks,
            HomeSection.urgentTasks,
            HomeSection.selectedTagTasks,
          ],
          hiddenHomeSections: {HomeSection.urgentTasks},
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
      expect(saved.homeSectionOrder.first, HomeSection.calendar);
      expect(saved.hiddenHomeSections, {HomeSection.urgentTasks});
      expect(saved.hiddenTagIds, {'tag-2'});
      expect(saved.hiddenFolderIds, {'folder-1'});
      expect(saved.tagFolderIds, isEmpty);
      expect(saved.tagSortOrders, {'tag-2': 1});
      expect(saved.ecampusFolderId, 'folder-ecampus');
      expect((await database.select(database.appSettings).get()).length, 15);

      final restartedRepository = DriftSettingsRepository(database: database);
      final persisted = await restartedRepository.getSettings();

      expect(persisted.autoSyncEnabled, isFalse);
      expect(persisted.saveEcampusAccount, isFalse);
      expect(persisted.defaultNotificationEnabled, isFalse);
      expect(persisted.defaultNotificationDays, 180);
      expect(persisted.defaultNotificationTime, 'relative');
      expect(persisted.urgentDueDays, 7);
      expect(persisted.homeSelectedTagId, 'tag-1');
      expect(persisted.homeSectionOrder, saved.homeSectionOrder);
      expect(persisted.hiddenHomeSections, saved.hiddenHomeSections);
      expect(persisted.hiddenTagIds, {'tag-2'});
      expect(persisted.hiddenFolderIds, {'folder-1'});
      expect(persisted.tagFolderIds, isEmpty);
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
      expect(cleared.homeSectionOrder, saved.homeSectionOrder);
      expect(cleared.hiddenHomeSections, saved.hiddenHomeSections);
      expect(cleared.hiddenTagIds, isEmpty);
      expect(cleared.hiddenFolderIds, isEmpty);
      expect(cleared.tagFolderIds, isEmpty);
      expect(cleared.tagSortOrders, {'tag-2': 0});
      expect(cleared.ecampusFolderId, isNull);
    });

    test('persists home layout across a database close and reopen', () async {
      await database.close();
      final directory = await Directory.systemTemp.createTemp(
        'ku_home_layout_',
      );
      final file = File('${directory.path}/settings.sqlite');
      final firstDatabase = AppDatabase(NativeDatabase(file));
      final firstRepository = DriftSettingsRepository(database: firstDatabase);
      final settings = await firstRepository.getSettings();
      final order = HomeSection.values.reversed.toList();
      try {
        await firstRepository.saveSettings(
          settings.copyWith(
            homePeriod: HomePeriodPreference(
              mode: HomePeriod.custom,
              start: DateTime(2030, 11, 12),
              end: DateTime(2030, 11, 14),
            ),
            homeSectionOrder: order,
            hiddenHomeSections: {HomeSection.todayTasks},
            taskSwipes: const TaskSwipeOptions(
              right: TaskSwipeAction.edit,
              left: TaskSwipeAction.complete,
              trashRight: TaskSwipeAction.deletePermanently,
              trashLeft: TaskSwipeAction.restore,
            ),
            homeView: const HomeViewOptions(
              sort: HomeSort.newest,
              statuses: {TaskStatus.active},
              priorities: {TaskPriority.high},
              tagIds: {'tag-a', 'tag-b'},
            ),
          ),
        );
      } finally {
        await firstDatabase.close();
      }

      database = AppDatabase(NativeDatabase(file));
      try {
        final loaded = await DriftSettingsRepository(
          database: database,
        ).getSettings();
        expect(loaded.homePeriod.mode, HomePeriod.custom);
        expect(loaded.homePeriod.start, DateTime(2030, 11, 12));
        expect(loaded.homePeriod.end, DateTime(2030, 11, 14));
        final updated = await DriftSettingsRepository(
          database: database,
        ).saveSettings(loaded.copyWith(urgentDueDays: 7));
        expect(updated.homePeriod.encode(), loaded.homePeriod.encode());
        expect(loaded.homeSectionOrder, order);
        expect(loaded.hiddenHomeSections, {HomeSection.todayTasks});
        expect(loaded.homeView.sort, HomeSort.newest);
        expect(loaded.homeView.statuses, {TaskStatus.active});
        expect(loaded.homeView.priorities, {TaskPriority.high});
        expect(loaded.homeView.tagIds, {'tag-a', 'tag-b'});
        expect(
          loaded.taskSwipes.encode(),
          const TaskSwipeOptions(
            right: TaskSwipeAction.edit,
            left: TaskSwipeAction.complete,
            trashRight: TaskSwipeAction.deletePermanently,
            trashLeft: TaskSwipeAction.restore,
          ).encode(),
        );
      } finally {
        await database.close();
        await directory.delete(recursive: true);
      }
    });
  });

  group('home layout settings compatibility', () {
    const mapper = AppSettingsMapper();

    test(
      'period preferences tolerate old or invalid data and preserve valid date ranges',
      () {
        for (final raw in [
          null,
          '{broken',
          '[]',
          '{}',
          '{"mode":"unknown"}',
          '{"mode":"all"}',
          '{"mode":"custom"}',
          '{"mode":"custom","start":"2030-11-14","end":"2030-11-12"}',
          '{"mode":"custom","start":"2030-02-30","end":"2030-03-02"}',
          '{"mode":"custom","start":"1999-12-31","end":"2000-01-01"}',
          '{"mode":"custom","start":12,"end":false}',
        ]) {
          expect(HomePeriodPreference.decode(raw).mode, HomePeriod.today);
        }
        for (final mode in HomePeriod.values.where(
          (m) => m != HomePeriod.custom && m != HomePeriod.all,
        )) {
          final preference = HomePeriodPreference(mode: mode);
          final loaded = mapper.fromMap({'homePeriod': preference.encode()});
          expect(loaded.homePeriod.mode, mode);
          expect(
            mapper
                .fromMap(mapper.toMap(loaded.copyWith(urgentDueDays: 7)))
                .homePeriod
                .mode,
            mode,
          );
        }
        for (final endDay in [12, 14]) {
          final preference = HomePeriodPreference(
            mode: HomePeriod.custom,
            start: DateTime(2030, 11, 12),
            end: DateTime(2030, 11, endDay),
          );
          final loaded = HomePeriodPreference.decode(preference.encode());
          expect(loaded.start, preference.start);
          expect(loaded.end, preference.end);
        }
        expect(mapper.fromMap({}).homePeriod.mode, HomePeriod.today);
      },
    );

    test(
      'swipe settings accept old data, reject invalid domains, and preserve unrelated fields',
      () {
        const defaults = TaskSwipeOptions();
        for (final raw in [null, '{broken', '[]', 'null']) {
          final values = raw == null ? <String, String>{} : {'taskSwipes': raw};
          expect(mapper.fromMap(values).taskSwipes.encode(), defaults.encode());
        }
        final loaded = mapper.fromMap({
          'taskSwipes':
              '{"right":"restore","left":"edit","trashRight":"delete","trashLeft":"future"}',
        });
        expect(loaded.taskSwipes.right, defaults.right);
        expect(loaded.taskSwipes.left, TaskSwipeAction.edit);
        expect(loaded.taskSwipes.trashRight, defaults.trashRight);
        expect(loaded.taskSwipes.trashLeft, defaults.trashLeft);
        expect(
          loaded.copyWith(urgentDueDays: 7).taskSwipes.encode(),
          loaded.taskSwipes.encode(),
        );
        expect(
          mapper.fromMap(mapper.toMap(loaded)).taskSwipes.encode(),
          loaded.taskSwipes.encode(),
        );
      },
    );

    test(
      'view settings tolerate old or malformed values and retain an explicit empty status selection',
      () {
        expect(mapper.fromMap({}).homeView.isDefault, isTrue);
        expect(
          mapper.fromMap({'homeView': '{broken'}).homeView.isDefault,
          isTrue,
        );
        expect(mapper.fromMap({'homeView': '[]'}).homeView.isDefault, isTrue);
        expect(
          mapper
              .fromMap({'homeView': '{"sort":"future","statuses":false}'})
              .homeView
              .isDefault,
          isTrue,
        );
        final empty = mapper.fromMap({
          'homeView': const HomeViewOptions(statuses: {}).encode(),
        });
        expect(empty.homeView.statuses, isEmpty);
        expect(empty.copyWith(urgentDueDays: 7).homeView.statuses, isEmpty);
      },
    );

    test('loads legacy settings with the four original visible sections', () {
      final settings = mapper.fromMap({'urgentDueDays': '7'});
      expect(settings.homeSectionOrder, HomeSection.values);
      expect(settings.hiddenHomeSections, {HomeSection.calendar});
      expect(settings.urgentDueDays, 7);
    });

    test('repairs duplicate, unknown and missing section IDs', () {
      final settings = mapper.fromMap({
        'homeSectionOrder': '["overdueTasks","futureSection","overdueTasks"]',
        'hiddenHomeSections': '["urgentTasks","futureSection"]',
      });
      expect(settings.homeSectionOrder, [
        HomeSection.overdueTasks,
        HomeSection.todayTasks,
        HomeSection.urgentTasks,
        HomeSection.selectedTagTasks,
        HomeSection.calendar,
      ]);
      expect(settings.hiddenHomeSections, {HomeSection.urgentTasks});
    });

    test('uses safe defaults for malformed stored values', () {
      for (final invalid in ['{broken', '{}', 'null', '[42]']) {
        final settings = mapper.fromMap({
          'homeSectionOrder': invalid,
          'hiddenHomeSections': invalid,
        });
        expect(settings.homeSectionOrder, HomeSection.values);
        expect(settings.hiddenHomeSections, {HomeSection.calendar});
      }
    });

    test('preserves explicit show-all and hide-all configurations', () {
      final settings = mapper.fromMap({});
      for (final hidden in [<HomeSection>{}, HomeSection.values.toSet()]) {
        final loaded = mapper.fromMap(
          mapper.toMap(settings.copyWith(hiddenHomeSections: hidden)),
        );
        expect(loaded.hiddenHomeSections, hidden);
      }
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
