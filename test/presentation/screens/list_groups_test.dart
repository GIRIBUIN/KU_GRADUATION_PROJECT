import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ku_task_management/core/utils/list_defaults.dart';
import 'package:ku_task_management/data/local/app_database.dart' as db;
import 'package:ku_task_management/data/models/task_models.dart';
import 'package:ku_task_management/data/repositories/drift_folder_repository.dart';
import 'package:ku_task_management/data/repositories/drift_notification_repository.dart';
import 'package:ku_task_management/data/repositories/drift_settings_repository.dart';
import 'package:ku_task_management/data/repositories/drift_sub_task_repository.dart';
import 'package:ku_task_management/data/repositories/drift_tag_repository.dart';
import 'package:ku_task_management/data/repositories/drift_task_repository.dart';
import 'package:ku_task_management/data/services/widget_update_service.dart';
import 'package:ku_task_management/presentation/screens/main/main_shell_screen.dart';
import 'package:ku_task_management/presentation/screens/task/task_create_screen.dart';
import 'package:ku_task_management/presentation/services/local_notification_service.dart';

void main() {
  setUpAll(() => initializeDateFormatting('ko_KR'));
  late db.AppDatabase database;
  late DriftTaskRepository tasks;
  late DriftFolderRepository lists;
  late DriftSettingsRepository settings;
  late DriftTagRepository tags;
  setUp(() {
    database = db.AppDatabase(NativeDatabase.memory());
    tasks = DriftTaskRepository(database: database);
    lists = DriftFolderRepository(database: database);
    settings = DriftSettingsRepository(database: database);
    tags = DriftTagRepository(database: database);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('home_widget'), (
          call,
        ) async {
          if (call.method == 'getWidgetData') {
            return (call.arguments as Map?)?['defaultValue'];
          }
          return null;
        });
  });
  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('home_widget'), null);
    await database.close();
  });

  Future<void> screen(WidgetTester tester, Widget home) async {
    await tester.binding.setSurfaceSize(const Size(360, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home: home));
    await tester.pumpAndSettle();
  }

  MainShellScreen mainScreen() => MainShellScreen(
    taskRepository: tasks,
    subTaskRepository: DriftSubTaskRepository(database: database),
    notificationRepository: DriftNotificationRepository(database: database),
    settingsRepository: settings,
    tagRepository: tags,
    folderRepository: lists,
    localNotificationService: _Notifications(),
    widgetUpdateService: _Widgets(tasks: tasks, settings: settings, tags: tags),
  );

  Future<void> openManagement(WidgetTester tester) async {
    await screen(tester, mainScreen());
    await tester.tap(find.text('관리').last);
    await tester.pumpAndSettle();
  }

  Future<void> seedCourse({String? groupId}) async {
    final now = DateTime.now();
    await lists.saveGroup(
      FolderGroup(id: 'school', name: 'School', createdAt: now, updatedAt: now),
    );
    await lists.createFolder(
      Folder(
        id: 'course',
        name: 'Course 1',
        groupId: groupId,
        color: '#123456',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await tasks.createTask(
      Task(
        id: 'task',
        title: 'Course task',
        origin: TaskOrigin.personal,
        status: TaskStatus.active,
        folderIds: const ['course'],
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> dragList(WidgetTester tester, Finder destination) async {
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('task-list-course'))),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveTo(tester.getCenter(destination));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.up();
    await tester.pumpAndSettle();
  }

  testWidgets('folder tap only expands lists; list tap opens its tasks', (
    tester,
  ) async {
    await seedCourse(groupId: 'school');
    await openManagement(tester);
    expect(find.text('Course 1'), findsNothing);
    await tester.tap(find.text('School'));
    await tester.pumpAndSettle();
    expect(find.text('Course 1'), findsOneWidget);
    expect(find.text('목록의 할 일'), findsNothing);
    await tester.tap(find.text('School'));
    await tester.pumpAndSettle();
    expect(find.text('Course 1'), findsNothing);
    await tester.tap(find.text('School'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Course 1'));
    await tester.pumpAndSettle();
    expect(find.text('목록의 할 일'), findsOneWidget);
    expect(find.text('Course task'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'long press moves a list into a folder and back out without moving its tasks',
    (tester) async {
      await seedCourse();
      await openManagement(tester);
      await dragList(tester, find.byKey(const ValueKey('folder-group-school')));
      expect((await lists.getFolderById('course'))!.groupId, 'school');
      expect(find.text('Course 1'), findsOneWidget);
      expect((await tasks.getTaskById('task'))!.listId, 'course');
      await dragList(tester, find.text('폴더 밖'));
      expect((await lists.getFolderById('course'))!.groupId, isNull);
      expect((await tasks.getTaskById('task'))!.listId, 'course');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('Inbox uses the same colored square but remains a fixed list', (
    tester,
  ) async {
    await seedCourse();
    await openManagement(tester);
    final inbox = find.byKey(const ValueKey('task-list-kutodo:inbox'));
    final course = find.byKey(const ValueKey('task-list-course'));
    final inboxIcon = find.descendant(
      of: inbox,
      matching: find.byIcon(Icons.square_rounded),
    );
    expect(inboxIcon, findsOneWidget);
    expect(
      tester
          .widget<Icon>(
            find.descendant(
              of: course,
              matching: find.byIcon(Icons.square_rounded),
            ),
          )
          .color,
      const Color(0xFF123456),
    );
    expect(
      find.descendant(
        of: inbox,
        matching: find.byWidgetPredicate((w) => w is LongPressDraggable),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byTooltip('목록 추가'),
        matching: find.byIcon(Icons.square_rounded),
      ),
      findsOneWidget,
    );
    await tester.tap(
      find.descendant(of: inbox, matching: find.byTooltip('편집')),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField).first).enabled,
      isFalse,
    );
    expect(
      tester
          .widget<DropdownButtonFormField<String>>(
            find.byType(DropdownButtonFormField<String>),
          )
          .onChanged,
      isNull,
    );
    expect(find.text('목록 보관'), findsNothing);
    expect(find.text('숨김'), findsNothing);
    await tester.enterText(find.byType(TextField).last, '#EF4444');
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await tester.pumpAndSettle();
    final saved = (await lists.getFolderById(inboxListId))!;
    expect(saved.name, '미지정');
    expect(saved.groupId, isNull);
    expect(saved.color, '#EF4444');
    expect(tester.widget<Icon>(inboxIcon).color, const Color(0xFFEF4444));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'new task defaults to Inbox and no unassigned choice is exposed',
    (tester) async {
      await settings.saveSettings(
        (await settings.getSettings()).copyWith(
          defaultNotificationEnabled: false,
        ),
      );
      await screen(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              child: const Text('Open'),
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
                    folderRepository: lists,
                    localNotificationService: _Notifications(),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(FilterChip, '미지정'), findsOneWidget);
      expect(
        tester
            .widget<FilterChip>(find.widgetWithText(FilterChip, '미지정'))
            .selected,
        isTrue,
      );
      expect(find.widgetWithText(FilterChip, '없음'), findsNothing);
      await tester.enterText(find.byType(TextField).first, 'Inbox task');
      await tester.tap(find.text('저장').first);
      await tester.pumpAndSettle();
      expect((await tasks.getTasks()).single.listId, inboxListId);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'management creates a School folder and puts a course list under it',
    (tester) async {
      await screen(tester, mainScreen());
      expect(find.text('홈'), findsOneWidget);
      await tester.tap(find.text('관리').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('상위 폴더 추가'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'School');
      await tester.tap(find.widgetWithText(FilledButton, '저장'));
      await tester.pumpAndSettle();
      final group = (await lists.getGroups()).single;
      await tester.tap(find.byTooltip('목록 추가'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Course 1');
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('폴더 밖'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('School').last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '저장'));
      await tester.pumpAndSettle();
      expect(
        (await lists.getFolders())
            .singleWhere((l) => l.name == 'Course 1')
            .groupId,
        group.id,
      );
      expect(find.text('School'), findsOneWidget);
      expect(find.text('Course 1'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'archival and restore through management retain completed task list',
    (tester) async {
      final now = DateTime.now();
      await lists.createFolder(
        Folder(id: 'course', name: 'Course 1', createdAt: now, updatedAt: now),
      );
      await tasks.createTask(
        Task(
          id: 'task',
          title: 'Completed',
          origin: TaskOrigin.personal,
          status: TaskStatus.active,
          folderIds: const ['course'],
          createdAt: now,
          updatedAt: now,
        ),
      );
      await tasks.updateTaskStatus('task', TaskStatus.completed);
      await screen(tester, mainScreen());
      await tester.tap(find.text('관리').last);
      await tester.pumpAndSettle();
      final row = find.ancestor(
        of: find.text('Course 1'),
        matching: find.byType(ListTile),
      );
      await tester.tap(
        find.descendant(of: row, matching: find.byTooltip('편집')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('목록 보관').last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '보관'));
      await tester.pumpAndSettle();
      expect(find.text('보관된 목록'), findsOneWidget);
      expect((await tasks.getTaskById('task'))!.listId, 'course');
      await tester.ensureVisible(find.text('목록 복원'));
      await tester.tap(find.text('목록 복원'));
      await tester.pumpAndSettle();
      expect((await lists.getFolderById('course'))!.archivedAt, isNull);
      expect((await tasks.getTaskById('task'))!.status, TaskStatus.completed);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}

class _Notifications extends LocalNotificationService {
  @override
  Future<void> scheduleTaskNotification({
    required Task task,
    required NotificationSetting setting,
    bool requestPermissionBeforeScheduling = false,
  }) async {}
}

class _Widgets extends WidgetUpdateService {
  _Widgets({
    required DriftTaskRepository tasks,
    required DriftSettingsRepository settings,
    required DriftTagRepository tags,
  }) : super(
         taskRepository: tasks,
         settingsRepository: settings,
         tagRepository: tags,
       );
  @override
  Future<void> refresh() async {}
  @override
  Future<void> applyPendingWidgetCompletions() async {}
}
