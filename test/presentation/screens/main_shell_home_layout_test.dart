import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Repositories repositories;

  setUp(() {
    repositories = _Repositories();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('home_widget'),
      (_) async => null,
    );
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

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(600, 1800);
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
          localNotificationService: LocalNotificationService(),
          widgetUpdateService: _WidgetService(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder section(HomeSection section) =>
      find.byKey(ValueKey('home-section-${section.id}'));

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
      expect(find.text('캘린더 기능 준비 중'), findsOneWidget);
      expect(repositories.tasks.single.status, TaskStatus.active);
      expect(find.text('태그가 있는 작업'), findsOneWidget);
      expect(tester.takeException(), isNull);
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

  @override
  Future<AppSettings> getSettings() async => settings;

  @override
  Future<AppSettings> saveSettings(AppSettings value) async => settings = value;

  @override
  Future<List<Task>> getTasks({
    TaskStatus? status,
    TaskOrigin? origin,
    bool includeArchived = false,
  }) async => tasks;

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
