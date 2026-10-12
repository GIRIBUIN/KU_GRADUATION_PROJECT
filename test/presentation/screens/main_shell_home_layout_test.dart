import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ku_task_management/core/theme/app_theme.dart';
import 'package:ku_task_management/data/models/home_section.dart';
import 'package:ku_task_management/data/models/task_models.dart';
import 'package:ku_task_management/data/repositories/folder_repository.dart';
import 'package:ku_task_management/data/repositories/notification_repository.dart';
import 'package:ku_task_management/data/repositories/settings_repository.dart';
import 'package:ku_task_management/data/repositories/sub_task_repository.dart';
import 'package:ku_task_management/data/repositories/tag_repository.dart';
import 'package:ku_task_management/data/repositories/task_repository.dart';
import 'package:ku_task_management/data/services/widget_update_service.dart';
import 'package:ku_task_management/presentation/screens/main/main_shell_screen.dart';
import 'package:ku_task_management/presentation/services/local_notification_service.dart';
import 'package:ku_task_management/presentation/widgets/home_calendar_section.dart';
import 'package:ku_task_management/presentation/screens/task/task_create_screen.dart';
import 'package:ku_task_management/presentation/screens/task/task_detail_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => initializeDateFormatting('ko_KR'));
  late _Repositories repositories;
  late Map<String, Object?> widgetData;

  setUp(() {
    repositories = _Repositories();
    widgetData = {};
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(const MethodChannel('home_widget'), (
      call,
    ) async {
      final arguments = call.arguments as Map?;
      if (call.method == 'getWidgetData') {
        return widgetData[arguments!['id']] ?? arguments['defaultValue'];
      }
      if (call.method == 'saveWidgetData') {
        widgetData[arguments!['id'] as String] = arguments['data'];
        return true;
      }
      return null;
    });
    messenger.setMockMethodCallHandler(
      const MethodChannel('home_widget/updates'),
      (_) async => null,
    );
  });

  tearDown(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('home_widget'),
      null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('home_widget/updates'),
      null,
    );
  });

  Future<void> pumpApp(
    WidgetTester tester, {
    WidgetUpdateService? widgetService,
  }) async {
    tester.view.physicalSize = const Size(600, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: MainShellScreen(
          taskRepository: repositories,
          subTaskRepository: repositories,
          notificationRepository: repositories,
          settingsRepository: repositories,
          tagRepository: repositories,
          folderRepository: repositories,
          localNotificationService: _Notifications(),
          widgetUpdateService: widgetService ?? _WidgetService(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder section(HomeSection section) =>
      find.byKey(ValueKey('home-section-${section.id}'));

  for (final completed in [true, false]) {
    testWidgets(
      'applies weekly widget ${completed ? 'completion' : 'uncompletion'} before reloading the calendar on resume',
      (tester) async {
        final now = DateTime.now();
        repositories.settings = repositories.settings.copyWith(
          hiddenHomeSections: HomeSection.values
              .where((section) => section != HomeSection.calendar)
              .toSet(),
        );
        repositories.tasks[0] = Task(
          id: 'task-1',
          origin: TaskOrigin.personal,
          status: completed ? TaskStatus.active : TaskStatus.completed,
          title: '위젯에서 변경한 일정',
          dueDate: now,
          createdAt: now,
          updatedAt: now,
        );
        await pumpApp(
          tester,
          widgetService: _PendingWidgetService(repositories),
        );
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        widgetData[WidgetUpdateService.widgetRefreshRequiredKey] = true;
        final pendingKey = completed
            ? WidgetUpdateService.widgetPendingCompletionsKey
            : WidgetUpdateService.widgetPendingUncompletionsKey;
        widgetData[pendingKey] = jsonEncode(['task-1']);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pumpAndSettle();

        expect(
          repositories.tasks.single.status,
          completed ? TaskStatus.completed : TaskStatus.active,
        );
        final checkbox = find.descendant(
          of: find.byKey(const ValueKey('calendar-task-task-1')),
          matching: find.byType(Checkbox),
        );
        expect(tester.widget<Checkbox>(checkbox).value, completed);
        expect(widgetData[pendingKey], isNull);
        expect(
          widgetData[WidgetUpdateService.widgetRefreshRequiredKey],
          isNull,
        );
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets(
    'settings editor updates home without changing tasks or the selected tag',
    (tester) async {
      await pumpApp(tester);
      expect(section(HomeSection.calendar), findsNothing);
      for (final value in HomeSection.values.where(
        (value) => value != HomeSection.calendar,
      )) {
        expect(section(value), findsOneWidget);
      }
      final tagPicker = find.byType(DropdownButtonFormField<String?>);
      await tester.tap(tagPicker);
      await tester.pumpAndSettle();
      await tester.tap(find.text('전공').last);
      await tester.pumpAndSettle();
      expect(repositories.settings.homeSelectedTagId, 'tag-1');

      await tester.tap(find.byTooltip('설정').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('홈 화면 구성'));
      await tester.pumpAndSettle();
      for (final id in ['todayTasks', 'calendar']) {
        await tester.tap(
          find.descendant(
            of: find.byKey(ValueKey(id)),
            matching: find.byType(Switch),
          ),
        );
      }
      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();
      expect(repositories.settings.homeSelectedTagId, 'tag-1');
      expect(repositories.settings.hiddenHomeSections, {
        HomeSection.todayTasks,
      });

      // Another settings write must preserve both the tag choice and home layout.
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(repositories.settings.defaultNotificationEnabled, false);
      expect(repositories.settings.homeSelectedTagId, 'tag-1');
      expect(repositories.settings.hiddenHomeSections, {
        HomeSection.todayTasks,
      });
      await tester.tap(find.text('홈'));
      await tester.pumpAndSettle();
      expect(section(HomeSection.todayTasks), findsNothing);
      expect(section(HomeSection.calendar), findsOneWidget);
      expect(find.byType(HomeCalendarSection), findsOneWidget);
      expect(repositories.tasks.single.status, TaskStatus.active);
      expect(find.text('태그가 있는 작업'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('creates and edits calendar tasks in the shared app repository', (
    tester,
  ) async {
    repositories.settings = repositories.settings.copyWith(
      hiddenHomeSections: {
        HomeSection.todayTasks,
        HomeSection.urgentTasks,
        HomeSection.selectedTagTasks,
        HomeSection.overdueTasks,
      },
    );
    await pumpApp(tester);
    await tester.tap(find.byTooltip('선택한 날짜에 일정 추가'));
    await tester.pumpAndSettle();
    final createScreen = tester.widget<TaskCreateScreen>(
      find.byType(TaskCreateScreen),
    );
    final date = createScreen.initialDueDate!;
    expect(date.hour, 23);
    expect(date.minute, 59);
    await tester.enterText(find.byType(TextField).first, '캘린더에서 추가한 일정');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    final created = repositories.tasks.last;
    expect(created.dueDate, date);
    expect(created.origin, TaskOrigin.personal);
    expect(find.byKey(ValueKey('calendar-task-${created.id}')), findsOneWidget);
    expect(repositories.notifications[created.id], isNotNull);

    await tester.tap(find.byKey(ValueKey('calendar-task-${created.id}')));
    await tester.pumpAndSettle();
    expect(find.byType(TaskDetailScreen), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '수정한 일정');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(find.text('수정한 일정'), findsOneWidget);
    expect(repositories.tasks.last.title, '수정한 일정');
    await tester.tap(find.byTooltip('수정한 일정 일정 메뉴'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
    expect(repositories.tasks.last.status, TaskStatus.deleted);
    expect(find.byKey(ValueKey('calendar-task-${created.id}')), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'a prefilled calendar date alone can be cancelled without a draft prompt',
    (tester) async {
      repositories.settings = repositories.settings.copyWith(
        hiddenHomeSections: {},
      );
      await pumpApp(tester);
      await tester.tap(find.byTooltip('선택한 날짜에 일정 추가'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(TaskCreateScreen), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
      expect(repositories.tasks.length, 1);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('loads saved order and supports hiding every section', (
    tester,
  ) async {
    repositories.settings = repositories.settings.copyWith(
      homeSectionOrder: HomeSection.values.reversed.toList(),
      hiddenHomeSections: {},
    );
    await pumpApp(tester);
    final positions = HomeSection.values.reversed
        .map((value) => tester.getTopLeft(section(value)).dy)
        .toList();
    expect(positions, orderedEquals([...positions]..sort()));
    await tester.pumpWidget(const SizedBox.shrink());

    repositories.settings = repositories.settings.copyWith(
      hiddenHomeSections: HomeSection.values.toSet(),
    );
    await pumpApp(tester);
    for (final value in HomeSection.values) {
      expect(section(value), findsNothing);
    }
    expect(find.text('표시 중인 홈 섹션이 없습니다.'), findsOneWidget);
    await tester.tap(find.byTooltip('설정').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('홈 화면 구성'));
    await tester.pumpAndSettle();
    expect(find.byType(ReorderableListView), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

class _WidgetService extends Fake implements WidgetUpdateService {
  @override
  Future<void> refresh() async {}
}

class _PendingWidgetService extends WidgetUpdateService {
  _PendingWidgetService(_Repositories repositories)
    : super(
        taskRepository: repositories,
        settingsRepository: repositories,
        tagRepository: repositories,
      );

  @override
  Future<void> refresh() => applyPendingWidgetCompletions();
}

class _Notifications extends Fake implements LocalNotificationService {
  @override
  Future<void> scheduleTaskNotification({
    required Task task,
    required NotificationSetting setting,
    bool requestPermissionBeforeScheduling = false,
  }) async {}

  @override
  Future<void> cancelTaskNotification(String taskId) async {}
}

class _Repositories extends Fake
    implements
        TaskRepository,
        SubTaskRepository,
        TagRepository,
        FolderRepository,
        NotificationRepository,
        SettingsRepository {
  AppSettings settings = const AppSettings(
    autoSyncEnabled: false,
    saveEcampusAccount: false,
    defaultNotificationEnabled: true,
    defaultNotificationDays: 60,
    defaultNotificationTime: 'relative',
    urgentDueDays: 3,
  );
  final tasks = [
    Task(
      id: 'task-1',
      origin: TaskOrigin.personal,
      status: TaskStatus.active,
      title: '태그가 있는 작업',
      tagIds: ['tag-1'],
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ),
  ];
  final Map<String, NotificationSetting> notifications = {};

  @override
  Future<Task> createTask(Task value) async {
    tasks.add(value);
    return value;
  }

  @override
  Future<Task?> getTaskById(String id) async =>
      tasks.where((task) => task.id == id).firstOrNull;

  @override
  Future<Task> updateTask(Task value) async {
    tasks[tasks.indexWhere((task) => task.id == value.id)] = value;
    return value;
  }

  @override
  Future<Task> updateTaskStatus(String id, TaskStatus status) async {
    final old = (await getTaskById(id))!;
    return updateTask(
      Task(
        id: old.id,
        origin: old.origin,
        status: status,
        title: old.title,
        dueDate: old.dueDate,
        createdAt: old.createdAt,
        updatedAt: old.updatedAt,
        tagIds: old.tagIds,
      ),
    );
  }

  @override
  Future<Task> markDeleted(String id) async {
    final old = (await getTaskById(id))!;
    return updateTask(
      Task(
        id: old.id,
        title: old.title,
        status: TaskStatus.deleted,
        origin: old.origin,
        dueDate: old.dueDate,
        createdAt: old.createdAt,
        updatedAt: old.updatedAt,
      ),
    );
  }

  @override
  Future<NotificationSetting> save(NotificationSetting value) async =>
      notifications[value.taskId] = value;

  @override
  Future<NotificationSetting?> getByTaskId(String taskId) async =>
      notifications[taskId];

  @override
  Future<AppSettings> getSettings() async => settings;

  @override
  Future<AppSettings> saveSettings(AppSettings value) async => settings = value;

  @override
  Future<List<Task>> getTasks({
    TaskStatus? status,
    TaskOrigin? origin,
    bool includeArchived = false,
  }) async => List.of(tasks);

  @override
  Future<List<SubTask>> getSubTasks(String taskId) async => [];

  @override
  Future<List<Folder>> getFolders() async => [];

  @override
  Future<List<Tag>> getTags() async => [
    Tag(
      id: 'tag-1',
      name: '전공',
      color: '#1262D6',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ),
  ];
}
