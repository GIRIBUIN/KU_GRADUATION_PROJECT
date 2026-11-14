import 'dart:io';
import 'dart:ui' as ui;
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ku_task_management/core/theme/app_theme.dart';
import 'package:ku_task_management/core/utils/list_defaults.dart';
import 'package:ku_task_management/data/local/app_database.dart' as db;
import 'package:ku_task_management/data/models/home_view_options.dart';
import 'package:ku_task_management/data/models/home_period_preference.dart';
import 'package:ku_task_management/data/models/task_models.dart';
import 'package:ku_task_management/data/models/task_swipe_options.dart';
import 'package:ku_task_management/data/repositories/drift_folder_repository.dart';
import 'package:ku_task_management/data/repositories/drift_notification_repository.dart';
import 'package:ku_task_management/data/repositories/drift_settings_repository.dart';
import 'package:ku_task_management/data/repositories/settings_repository.dart';
import 'package:ku_task_management/data/repositories/drift_sub_task_repository.dart';
import 'package:ku_task_management/data/repositories/drift_tag_repository.dart';
import 'package:ku_task_management/data/repositories/drift_task_repository.dart';
import 'package:ku_task_management/data/services/widget_update_service.dart';
import 'package:ku_task_management/presentation/screens/main/main_shell_screen.dart';
import 'package:ku_task_management/presentation/screens/sync/ecampus_sync_progress_screen.dart';
import 'package:ku_task_management/presentation/screens/task/task_create_screen.dart';
import 'package:ku_task_management/presentation/screens/task/task_detail_screen.dart';
import 'package:ku_task_management/presentation/services/local_notification_service.dart';
import 'package:ku_task_management/presentation/widgets/home_calendar_section.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
    if (const bool.fromEnvironment('CAPTURE_UI')) {
      for (final (family, path) in [
        ('Roboto', r'C:\Windows\Fonts\malgun.ttf'),
        ('Ahem', r'C:\Windows\Fonts\malgun.ttf'),
        (
          'MaterialIcons',
          r'C:\flutter\bin\cache\artifacts\material_fonts\MaterialIcons-Regular.otf',
        ),
      ]) {
        final file = File(path);
        if (file.existsSync()) {
          await (FontLoader(family)..addFont(
                Future.value(ByteData.sublistView(file.readAsBytesSync())),
              ))
              .load();
        }
      }
    }
  });
  late db.AppDatabase database;
  late DriftTaskRepository tasks;
  late DriftFolderRepository lists;
  late DriftTagRepository tags;
  late DriftSettingsRepository settings;
  late _Notifications notifications;
  late DateTime now;
  late DateTime today;

  setUp(() async {
    now = DateTime.now();
    today = DateTime(now.year, now.month, now.day, 23, 59, 59);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('home_widget/updates'),
          (_) async => null,
        );
    database = db.AppDatabase(NativeDatabase.memory());
    tasks = DriftTaskRepository(database: database);
    lists = DriftFolderRepository(database: database);
    tags = DriftTagRepository(database: database);
    settings = DriftSettingsRepository(database: database);
    notifications = _Notifications();
    await settings.saveSettings(
      (await settings.getSettings()).copyWith(
        defaultNotificationEnabled: false,
      ),
    );
    await lists.saveGroup(
      FolderGroup(id: 'school', name: '학교', createdAt: now, updatedAt: now),
    );
    await lists.createFolder(
      Folder(
        id: 'course',
        name: '운영체제',
        groupId: 'school',
        createdAt: now,
        updatedAt: now,
      ),
    );
    for (final (id, name) in [('tag-a', '과제'), ('tag-b', '개인')]) {
      await tags.createTag(
        Tag(
          id: id,
          name: name,
          color: '#1262D6',
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
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
        .setMockMethodCallHandler(
          const MethodChannel('home_widget/updates'),
          null,
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('home_widget'), null);
    await database.close();
  });

  Future<Task> add(
    String id, {
    DateTime? due,
    String list = inboxListId,
    TaskPriority? priority,
    List<String> tagIds = const [],
    bool completed = false,
  }) async {
    final saved = await tasks.createTask(
      Task(
        id: id,
        title: id,
        origin: TaskOrigin.personal,
        status: TaskStatus.active,
        dueDate: due,
        priority: priority,
        folderIds: [list],
        tagIds: tagIds,
        createdAt: now,
        updatedAt: now,
      ),
    );
    if (completed) return tasks.updateTaskStatus(id, TaskStatus.completed);
    return saved;
  }

  Future<void> pumpApp(
    WidgetTester tester, {
    double textScale = 1,
    DriftNotificationRepository? reminders,
  }) async {
    final theme = AppTheme.light();
    // Widget tests normally replace platform fonts with Ahem. Use readable
    // local fonts only for optional documentation captures, not app assets.
    final captureTheme = theme.copyWith(
      appBarTheme: theme.appBarTheme.copyWith(
        titleTextStyle: theme.appBarTheme.titleTextStyle?.copyWith(
          fontFamily: 'Roboto',
        ),
      ),
      navigationBarTheme: theme.navigationBarTheme.copyWith(
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => theme.navigationBarTheme.labelTextStyle
              ?.resolve(states)
              ?.copyWith(fontFamily: 'Roboto'),
        ),
      ),
    );
    await tester.binding.setSurfaceSize(const Size(360, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      RepaintBoundary(
        key: const ValueKey('capture-home'),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: const bool.fromEnvironment('CAPTURE_UI')
              ? captureTheme
              : theme,
          locale: const Locale('ko'),
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: const [Locale('ko'), Locale('en')],
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: MainShellScreen(
            taskRepository: tasks,
            subTaskRepository: DriftSubTaskRepository(database: database),
            notificationRepository:
                reminders ?? DriftNotificationRepository(database: database),
            settingsRepository: settings,
            tagRepository: tags,
            folderRepository: lists,
            localNotificationService: notifications,
            widgetUpdateService: _Widgets(
              tasks: tasks,
              settings: settings,
              lists: lists,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> trashItem(
    String id, {
    bool completed = false,
    DateTime? due,
    List<String> tagIds = const [],
    TaskPriority? priority,
  }) async {
    await add(
      id,
      due: due ?? today,
      list: 'course',
      completed: completed,
      tagIds: tagIds,
      priority: priority,
    );
    await tasks.markDeleted(id);
  }

  Future<void> startTrashSelection(WidgetTester tester) async {
    final checkbox = find
        .descendant(
          of: find.byKey(const ValueKey('home-section-trash')),
          matching: find.byType(Checkbox),
        )
        .first;
    await tester.tap(checkbox);
    await tester.pumpAndSettle();
    await tester.tap(checkbox);
    await tester.pumpAndSettle();
  }

  Future<void> finish(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox.shrink());
  Future<void> restart(WidgetTester tester) async {
    await finish(tester);
    await pumpApp(tester);
  }

  Finder selectionCount(int count) => find.descendant(
    of: find.byKey(const ValueKey('selection-toolbar')),
    matching: find.text('$count'),
  );

  Finder row(String id, [String section = 'period']) =>
      find.byKey(ValueKey('home-task-$section-$id'));
  Future<void> openDrawer(WidgetTester tester) async {
    if (find.byType(Drawer).evaluate().isNotEmpty) return;
    await tester.tap(find.byTooltip('사이드 메뉴'));
    await tester.pumpAndSettle();
  }

  Future<void> chooseScope(
    WidgetTester tester,
    String kind, [
    String id = '',
  ]) async {
    await openDrawer(tester);
    final entry = find.byKey(ValueKey('scope-$kind-$id'));
    if (kind == 'list' && id == 'course' && entry.evaluate().isEmpty) {
      await tester.tap(find.byKey(const ValueKey('drawer-folder-school')));
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(entry);
    await tester.tap(entry);
    await tester.pumpAndSettle();
  }

  Future<void> choosePeriod(WidgetTester tester, String label) async {
    await tester.tap(find.byKey(const ValueKey('home-period')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  Future<void> adjust(WidgetTester tester) async {
    await tester.tap(find.byTooltip('보기 조정'));
    await tester.pumpAndSettle();
  }

  Future<void> swipeTask(
    WidgetTester tester,
    String id, {
    required bool toRight,
    String section = 'period',
  }) async {
    final target = row(id, section);
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    final rect = tester.getRect(target);
    await tester.flingFrom(
      Offset(toRight ? rect.left + 64 : rect.right - 24, rect.center.dy),
      Offset(toRight ? 220 : -220, 0),
      1000,
    );
    await tester.pumpAndSettle();
  }

  Future<void> openSwipeSettings(WidgetTester tester) async {
    await openDrawer(tester);
    await tester.tap(find.byKey(const ValueKey('drawer-settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('스와이프'));
    await tester.pumpAndSettle();
  }

  Future<void> chooseSwipe(
    WidgetTester tester,
    String id,
    TaskSwipeAction action,
  ) async {
    final field = find.byKey(ValueKey('swipe-setting-$id'));
    await tester.scrollUntilVisible(
      field,
      150,
      scrollable: find
          .descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.ensureVisible(field);
    await tester.tap(field);
    await tester.pumpAndSettle();
    await tester.tap(find.text(action.label).last);
    await tester.pumpAndSettle();
  }

  Future<void> dismissSheet(WidgetTester tester) async {
    await tester.tapAt(const Offset(8, 30));
    await tester.pumpAndSettle();
  }

  Future<void> capture(WidgetTester tester, String name) async {
    if (!const bool.fromEnvironment('CAPTURE_UI')) return;
    await tester.pumpAndSettle();
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('capture-home')),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final directory = Directory('docs/evidence/home-ui');
      await directory.create(recursive: true);
      await File(
        '${directory.path}/${const String.fromEnvironment('CAPTURE_PREFIX')}$name.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  Future<void> dragDrawer(
    WidgetTester tester,
    Finder source,
    Finder target, {
    bool after = false,
  }) async {
    await tester.ensureVisible(source);
    final gesture = await tester.startGesture(tester.getCenter(source));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const ValueKey('drawer-context-menu')), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    await capture(tester, 'context-menu');
    await gesture.moveBy(const Offset(0, -24));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const ValueKey('drawer-context-menu')), findsNothing);
    for (final text in ['목록 끝으로 이동', '태그 끝으로 이동', '폴더 밖으로 이동']) {
      expect(find.text(text), findsNothing);
    }
    await tester.ensureVisible(target);
    await tester.pump(const Duration(milliseconds: 100));
    final targetRect = tester.getRect(target);
    await gesture.moveTo(
      Offset(
        targetRect.center.dx,
        targetRect.top + targetRect.height * (after ? .75 : .25),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.up();
    await tester.pumpAndSettle();
  }

  testWidgets(
    'home defaults to today with four plain sections and empty states',
    (tester) async {
      await pumpApp(tester);
      for (final section in ['period', 'urgent', 'overdue', 'completed']) {
        expect(find.byKey(ValueKey('home-section-$section')), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(ValueKey('home-section-$section')),
            matching: find.text('0'),
          ),
          findsNothing,
        );
      }
      expect(find.textContaining('오늘 ·'), findsOneWidget);
      expect(find.text('할 일이 없습니다.'), findsNWidgets(4));
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.byType(NavigationDestination), findsNWidgets(3));
      for (final (id, label) in [
        ('nav-home', '홈'),
        ('nav-add', '빠른 추가'),
        ('nav-calendar', '캘린더'),
      ]) {
        final labelWidget = find.descendant(
          of: find.byKey(ValueKey(id)),
          matching: find.text(label),
        );
        final fade = find
            .ancestor(of: labelWidget, matching: find.byType(FadeTransition))
            .first;
        expect(tester.widget<FadeTransition>(fade).opacity.value, 0);
      }
      await openDrawer(tester);
      await tester.tap(find.byKey(const ValueKey('drawer-settings')));
      await tester.pumpAndSettle();
      expect(find.text('전체 일정 관리'), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await chooseScope(tester, 'all');
      expect(find.byKey(const ValueKey('home-section-period')), findsOneWidget);
      expect(find.text('할 일이 없습니다.'), findsNWidgets(4));
      expect(tester.takeException(), isNull);
      await finish(tester);
    },
  );

  testWidgets(
    'Drawer separates saved period and all dates with Inbox under Lists',
    (tester) async {
      await add('오늘 일정', due: today);
      await add('먼 마감', due: DateTime(now.year + 1, 6, 15), list: 'course');
      await add('과거 완료', due: today, completed: true);
      await (database.update(database.tasks)
            ..where((t) => t.id.equals('과거 완료')))
          .write(db.TasksCompanion(completedAt: Value(DateTime(2020, 1, 1))));
      await trashItem('휴지통 제외');
      await pumpApp(tester);
      await choosePeriod(tester, '이번 주');
      expect(row('먼 마감'), findsNothing);
      expect(row('과거 완료', 'completed'), findsNothing);
      await openDrawer(tester);
      final period = find.byKey(const ValueKey('scope-period-'));
      final all = find.byKey(const ValueKey('scope-all-'));
      expect(tester.widget<ListTile>(period).selected, isTrue);
      expect(
        (tester.widget<ListTile>(period).leading! as Icon).icon,
        Icons.access_time_outlined,
      );
      expect(
        (tester.widget<ListTile>(all).leading! as Icon).icon,
        Icons.description_outlined,
      );
      final inbox = find.byKey(const ValueKey('scope-list-$inboxListId'));
      expect(
        tester.getTopLeft(inbox).dy,
        greaterThan(tester.getTopLeft(find.text('목록')).dy),
      );
      expect(
        tester.getTopLeft(inbox).dy,
        greaterThan(tester.getTopLeft(all).dy),
      );
      await capture(tester, 'drawer-scopes');
      await tester.tap(all);
      await tester.pumpAndSettle();
      expect(row('먼 마감'), findsOneWidget);
      expect(row('과거 완료', 'completed'), findsOneWidget);
      expect(find.text('휴지통 제외'), findsNothing);
      await capture(tester, 'all-tasks');
      expect((await settings.getSettings()).homePeriod.mode, HomePeriod.week);
      expect(
        tester.widget<InkWell>(find.byKey(const ValueKey('home-period'))).onTap,
        isNull,
      );
      await tester.tap(row('먼 마감'));
      await tester.pumpAndSettle();
      expect(find.byType(TaskDetailScreen), findsOneWidget);
      expect(find.byType(BottomSheet), findsOneWidget);
      await tester.tap(find.byTooltip('작업 상세 닫기'));
      await tester.pumpAndSettle();
      await chooseScope(tester, 'period');
      expect(find.text('이번 주'), findsNWidgets(2));
      expect(row('먼 마감'), findsNothing);
      expect(row('과거 완료', 'completed'), findsNothing);
      expect(tester.takeException(), isNull);
      await finish(tester);
    },
  );

  testWidgets(
    'relative period choices persist without saving unsaved view filters',
    (tester) async {
      await pumpApp(tester);
      for (final (label, mode) in [
        ('이번 주', HomePeriod.week),
        ('이번 달', HomePeriod.month),
        ('오늘', HomePeriod.today),
      ]) {
        await choosePeriod(tester, label);
        expect((await settings.getSettings()).homePeriod.mode, mode);
        await restart(tester);
        if (mode == HomePeriod.today) {
          expect(find.textContaining('오늘 ·'), findsOneWidget);
        } else {
          expect(find.text(label), findsNWidgets(2));
        }
      }
      await adjust(tester);
      await tester.ensureVisible(find.widgetWithText(FilterChip, '높음'));
      await tester.tap(find.widgetWithText(FilterChip, '높음'));
      await dismissSheet(tester);
      await choosePeriod(tester, '이번 주');
      expect((await settings.getSettings()).homeView.isDefault, isTrue);
      await restart(tester);
      expect(find.text('이번 주'), findsNWidgets(2));
      expect((await settings.getSettings()).homeView.isDefault, isTrue);
      expect(tester.takeException(), isNull);
      await finish(tester);
    },
  );

  testWidgets('failed period persistence is reported and can be retried', (
    tester,
  ) async {
    final failing = _FailingSwipeSettings(database: database);
    settings = failing;
    await pumpApp(tester);
    await choosePeriod(tester, '이번 주');
    expect(find.text('기간을 저장하지 못했습니다. 다시 선택해주세요.'), findsOneWidget);
    expect((await settings.getSettings()).homePeriod.mode, HomePeriod.today);
    failing.failSave = false;
    await choosePeriod(tester, '이번 달');
    await restart(tester);
    expect(find.text('이번 달'), findsNWidgets(2));
    expect((await settings.getSettings()).homePeriod.mode, HomePeriod.month);
    expect(tester.takeException(), isNull);
    await finish(tester);
  });

  testWidgets(
    'Drawer list reordering persists and fixed Inbox cannot be dragged',
    (tester) async {
      for (final id in ['A', 'B', 'C']) {
        await lists.createFolder(
          Folder(id: id, name: id, createdAt: now, updatedAt: now),
        );
      }
      await pumpApp(tester);
      await openDrawer(tester);
      await dragDrawer(
        tester,
        find.byKey(const ValueKey('scope-list-C')),
        find.byKey(const ValueKey('drawer-drop-list-A')),
      );
      expect(
        (await lists.getFolders())
            .where((l) => ['A', 'B', 'C'].contains(l.id))
            .map((l) => l.id),
        ['C', 'A', 'B'],
      );
      await dragDrawer(
        tester,
        find.byKey(const ValueKey('scope-list-C')),
        find.byKey(const ValueKey('drawer-drop-list-B')),
        after: true,
      );
      expect(
        (await lists.getFolders())
            .where((l) => ['A', 'B', 'C'].contains(l.id))
            .map((l) => l.id),
        ['A', 'B', 'C'],
      );
      await restart(tester);
      await openDrawer(tester);
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('scope-list-A'))).dy,
        lessThan(
          tester.getTopLeft(find.byKey(const ValueKey('scope-list-C'))).dy,
        ),
      );
      final inbox = find.byKey(const ValueKey('drawer-item-list-$inboxListId'));
      expect(
        find.descendant(
          of: inbox,
          matching: find.byWidgetPredicate((w) => w is LongPressDraggable),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
      await finish(tester);
    },
  );

  testWidgets(
    'Drawer tag drag saves order, preserves settings and allows retry on failure',
    (tester) async {
      final failing = _FailingSwipeSettings(database: database)
        ..failSave = false;
      settings = failing;
      await settings.saveSettings(
        (await settings.getSettings()).copyWith(
          urgentDueDays: 8,
          hiddenFolderIds: {'other'},
        ),
      );
      await pumpApp(tester);
      await choosePeriod(tester, '이번 주');
      await openDrawer(tester);
      final beforeOrder = Map<String, int>.of(
        (await settings.getSettings()).tagSortOrders,
      );
      failing.failSave = true;
      await dragDrawer(
        tester,
        find.byKey(const ValueKey('scope-tag-tag-a')),
        find.byKey(const ValueKey('drawer-drop-tag-tag-b')),
      );
      expect(find.text('순서나 위치를 저장하지 못했습니다. 다시 시도해주세요.'), findsOneWidget);
      expect((await settings.getSettings()).tagSortOrders, beforeOrder);
      failing.failSave = false;
      await dragDrawer(
        tester,
        find.byKey(const ValueKey('scope-tag-tag-a')),
        find.byKey(const ValueKey('drawer-drop-tag-tag-b')),
      );
      final saved = await settings.getSettings();
      expect(saved.tagSortOrders, {'tag-a': 0, 'tag-b': 1});
      expect(saved.urgentDueDays, 8);
      expect(saved.homePeriod.mode, HomePeriod.week);
      expect(saved.hiddenFolderIds, {'other'});
      await restart(tester);
      await openDrawer(tester);
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('scope-tag-tag-a'))).dy,
        lessThan(
          tester.getTopLeft(find.byKey(const ValueKey('scope-tag-tag-b'))).dy,
        ),
      );
      await tester.longPress(find.byKey(const ValueKey('scope-tag-tag-a')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('drawer-context-menu')), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('drawer-context-menu')), findsNothing);
      expect(tester.takeException(), isNull);
      await finish(tester);
    },
  );

  testWidgets(
    'trash opens with an independent all-date period and resets on reentry and tab changes',
    (tester) async {
      await trashItem('오래된 휴지통');
      await (database.update(database.tasks)
            ..where((t) => t.id.equals('오래된 휴지통')))
          .write(db.TasksCompanion(deletedAt: Value(DateTime(2020, 1, 1))));
      await pumpApp(tester);
      await choosePeriod(tester, '이번 주');
      await chooseScope(tester, 'trash');
      expect(row('오래된 휴지통', 'trash'), findsOneWidget);
      await capture(tester, 'trash-all-dates');
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('home-period')),
          matching: find.text('전체'),
        ),
        findsOneWidget,
      );
      await choosePeriod(tester, '오늘');
      expect(row('오래된 휴지통', 'trash'), findsNothing);
      expect((await settings.getSettings()).homePeriod.mode, HomePeriod.week);
      await chooseScope(tester, 'trash');
      expect(row('오래된 휴지통', 'trash'), findsOneWidget);
      await chooseScope(tester, 'period');
      expect(find.text('이번 주'), findsNWidgets(2));
      await chooseScope(tester, 'trash');
      expect(row('오래된 휴지통', 'trash'), findsOneWidget);
      await choosePeriod(tester, '이번 달');
      await tester.tap(find.byKey(const ValueKey('nav-calendar')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('nav-home')));
      await tester.pumpAndSettle();
      expect(row('오래된 휴지통', 'trash'), findsOneWidget);
      expect((await settings.getSettings()).homePeriod.mode, HomePeriod.week);
      expect(tester.takeException(), isNull);
      await finish(tester);
    },
  );

  testWidgets(
    'excluded eCampus navigation is below trash and reuses allow-import handling',
    (tester) async {
      await tasks.createTask(
        Task(
          id: 'excluded',
          title: '제외 과제',
          origin: TaskOrigin.ecampus,
          status: TaskStatus.excluded,
          createdAt: now,
          updatedAt: now,
          ecampus: const EcampusSyncMetadata(
            sourceKey: 'course:1:report',
            sourceCourse: '운영체제',
          ),
        ),
      );
      await pumpApp(tester);
      await openDrawer(tester);
      final excluded = find.byKey(const ValueKey('drawer-excluded'));
      await tester.ensureVisible(excluded);
      expect(
        tester.getTopLeft(excluded).dy,
        greaterThan(
          tester.getTopLeft(find.byKey(const ValueKey('scope-trash-'))).dy,
        ),
      );
      await tester.tap(excluded);
      await tester.pumpAndSettle();
      expect(row('excluded', 'excluded'), findsOneWidget);
      expect(find.byType(BackButton), findsNothing);
      expect(find.byKey(const ValueKey('nav-home')), findsOneWidget);
      expect(find.byKey(const ValueKey('home-section-period')), findsNothing);
      expect(find.byType(Card), findsNothing);
      expect(find.text('동기화 제외'), findsNothing);
      expect(find.textContaining('허용하면 즉시'), findsNothing);
      expect(find.byType(Checkbox), findsOneWidget);
      await tester.drag(row('excluded', 'excluded'), const Offset(260, 0));
      await tester.pumpAndSettle();
      expect(
        (await tasks.getTaskById('excluded'))!.status,
        TaskStatus.excluded,
      );
      await openDrawer(tester);
      expect(tester.widget<ListTile>(excluded).selected, isTrue);
      await tester.tap(excluded);
      await tester.pumpAndSettle();
      await capture(tester, 'excluded-list');
      await tester.tap(row('excluded', 'excluded'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('excluded-restore-selected')));
      await tester.pumpAndSettle();
      expect(await tasks.getTaskById('excluded'), isNull);
      expect(find.text('제외 과제'), findsNothing);
      expect(find.text('할 일이 없습니다.'), findsOneWidget);
      expect(await database.select(database.tasks).get(), isEmpty);
      final source =
          (await database.select(database.ecampusItems).get()).single;
      expect(source.importState, 'unreviewed');
      expect(source.taskId, isNull);
      await capture(tester, 'excluded-empty');
      expect(tester.takeException(), isNull);
      await finish(tester);
    },
  );

  testWidgets(
    'excluded home scope ignores home dates and filters and keeps sorting temporary',
    (tester) async {
      const longTitle = '제외된 아주 긴 과제 제목을 줄바꿈하여 전체 내용을 표시합니다';
      for (final (id, title, days) in [
        ('late-source', longTitle, 50),
        ('early-source', '지난 과제', -50),
      ]) {
        await tasks.createTask(
          Task(
            id: id,
            title: title,
            origin: TaskOrigin.ecampus,
            status: TaskStatus.excluded,
            dueDate: now.add(Duration(days: days)),
            createdAt: now,
            updatedAt: now,
            ecampus: EcampusSyncMetadata(
              sourceKey: id,
              sourceCourse: '운영체제',
              sourceDueDate: now.add(Duration(days: days)),
            ),
          ),
        );
      }
      await add('일반 할 일', due: today);
      const view = HomeViewOptions(
        sort: HomeSort.priority,
        statuses: {},
        priorities: {TaskPriority.high},
        tagIds: {'tag-a'},
      );
      final original = await settings.saveSettings(
        (await settings.getSettings()).copyWith(
          homeView: view,
          homePeriod: const HomePeriodPreference(mode: HomePeriod.week),
        ),
      );
      await pumpApp(tester, textScale: 1.5);
      await openDrawer(tester);
      await tester.ensureVisible(find.byKey(const ValueKey('drawer-excluded')));
      await tester.tap(find.byKey(const ValueKey('drawer-excluded')));
      await tester.pumpAndSettle();
      expect(row('late-source', 'excluded'), findsOneWidget);
      expect(row('early-source', 'excluded'), findsOneWidget);
      expect(find.text('운영체제'), findsNWidgets(2));
      expect(find.text('미지정'), findsNothing);
      expect(find.text('일반 할 일'), findsNothing);
      final title = tester.widget<Text>(find.text(longTitle));
      expect(title.maxLines, isNull);
      expect(title.overflow, isNot(TextOverflow.ellipsis));
      expect(
        tester.widget<InkWell>(find.byKey(const ValueKey('home-period'))).onTap,
        isNull,
      );
      await tester.tap(find.byTooltip('보기 조정'));
      await tester.pumpAndSettle();
      expect(find.text('상태'), findsNothing);
      expect(find.byType(FilterChip), findsNothing);
      expect(find.text('저장'), findsNothing);
      await capture(tester, 'excluded-sort');
      await tester.tap(find.widgetWithText(ChoiceChip, '마감 늦은 순'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('닫기'));
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(row('late-source', 'excluded')).dy,
        lessThan(tester.getTopLeft(row('early-source', 'excluded')).dy),
      );
      await tester.tap(find.byTooltip('보기 조정'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, '마감 빠른 순'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('닫기'));
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(row('early-source', 'excluded')).dy,
        lessThan(tester.getTopLeft(row('late-source', 'excluded')).dy),
      );
      await capture(tester, 'excluded-large');
      expect(
        (await settings.getSettings()).homeView.encode(),
        original.homeView.encode(),
      );
      expect((await settings.getSettings()).homePeriod.mode, HomePeriod.week);
      await chooseScope(tester, 'all');
      await openDrawer(tester);
      await tester.ensureVisible(find.byKey(const ValueKey('drawer-excluded')));
      await tester.tap(find.byKey(const ValueKey('drawer-excluded')));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('보기 조정'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '기본'))
            .selected,
        isTrue,
      );
      expect(tester.takeException(), isNull);
      await finish(tester);
    },
  );

  testWidgets(
    'excluded allow-import failure retains the source and allows retry',
    (tester) async {
      final failing = _FailingExcludedTasks(database: database);
      tasks = failing;
      await tasks.createTask(
        Task(
          id: 'excluded-retry',
          title: '재시도 과제',
          origin: TaskOrigin.ecampus,
          status: TaskStatus.excluded,
          createdAt: now,
          updatedAt: now,
          ecampus: const EcampusSyncMetadata(sourceKey: 'retry-source'),
        ),
      );
      await pumpApp(tester);
      await openDrawer(tester);
      await tester.ensureVisible(find.byKey(const ValueKey('drawer-excluded')));
      await tester.tap(find.byKey(const ValueKey('drawer-excluded')));
      await tester.pumpAndSettle();
      await tester.tap(row('excluded-retry', 'excluded'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('excluded-restore-selected')));
      await tester.pumpAndSettle();
      expect(row('excluded-retry', 'excluded'), findsOneWidget);
      expect(find.textContaining('0개 처리, 1개 오류'), findsOneWidget);
      expect(
        (await tasks.getTaskById('excluded-retry'))!.status,
        TaskStatus.excluded,
      );
      failing.failDelete = false;
      await tester.tap(find.byKey(const ValueKey('excluded-restore-selected')));
      await tester.pumpAndSettle();
      expect(row('excluded-retry', 'excluded'), findsNothing);
      expect(await tasks.getTaskById('excluded-retry'), isNull);
      expect(tester.takeException(), isNull);
      await finish(tester);
    },
  );

  for (final textScale in [1.0, 1.5]) {
    testWidgets(
      'home task rows fully wrap titles and metadata at text scale $textScale',
      (tester) async {
        tester.view.physicalSize = const Size(360, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        const longTagName = '아주 긴 태그 이름을 줄바꿈해서 모두 확인';
        await tags.createTag(
          Tag(
            id: 'long-tag',
            name: longTagName,
            color: '#1262D6',
            createdAt: now,
            updatedAt: now,
          ),
        );
        await lists.createFolder(
          Folder(id: 'loose', name: '개인 목록', createdAt: now, updatedAt: now),
        );
        final title = List.filled(
          4,
          '운영체제 과제의 요구사항을 빠짐없이 확인하고 결과 정리하기',
        ).join(' ');
        await add(
          title,
          due: today,
          list: 'course',
          tagIds: ['tag-a', 'tag-b', 'long-tag'],
        );
        await add('짧은 제목', due: today);
        await add('폴더 없는 목록', due: today, list: 'loose', tagIds: ['tag-a']);
        await pumpApp(tester, textScale: textScale);
        final longRow = row(title);
        final titleFinder = find.descendant(
          of: longRow,
          matching: find.text(title),
        );
        final titleText = tester.widget<Text>(titleFinder);
        final paragraph = tester.renderObject<RenderParagraph>(titleFinder);
        expect(titleText.style!.fontSize, 13);
        expect(paragraph.didExceedMaxLines, isFalse);
        final lines = paragraph.getBoxesForSelection(
          TextSelection(baseOffset: 0, extentOffset: title.length),
        );
        expect(lines.map((box) => box.top).toSet().length, greaterThan(2));
        expect(
          paragraph.getBoxesForSelection(
            TextSelection(
              baseOffset: title.length - 4,
              extentOffset: title.length,
            ),
          ),
          isNotEmpty,
        );
        expect(
          tester.getSize(longRow).height,
          greaterThan(tester.getSize(row('짧은 제목')).height),
        );
        const metadata = '학교 > 운영체제 · #개인 · #과제 · #$longTagName';
        final metadataFinder = find.descendant(
          of: longRow,
          matching: find.text(metadata),
        );
        final metadataParagraph = tester.renderObject<RenderParagraph>(
          metadataFinder,
        );
        expect(metadataParagraph.didExceedMaxLines, isFalse);
        expect(
          metadataParagraph
              .getBoxesForSelection(
                const TextSelection(
                  baseOffset: 0,
                  extentOffset: metadata.length,
                ),
              )
              .map((box) => box.top)
              .toSet()
              .length,
          greaterThan(1),
        );
        expect(
          find.descendant(of: row('짧은 제목'), matching: find.text('미지정')),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: row('폴더 없는 목록'),
            matching: find.text('개인 목록 · #과제'),
          ),
          findsOneWidget,
        );
        await capture(
          tester,
          textScale == 1 ? 'wrapped-tasks' : 'wrapped-tasks-large',
        );
        await tester.tap(titleFinder);
        await tester.pumpAndSettle();
        expect(find.byType(TaskDetailScreen), findsOneWidget);
        await tester.tap(find.byTooltip('작업 상세 닫기'));
        await tester.pumpAndSettle();
        final saved = (await tasks.getTaskById(title))!;
        expect(saved.title, title);
        expect(saved.listId, 'course');
        expect(saved.tagIds.toSet(), {'tag-a', 'tag-b', 'long-tag'});
        expect(saved.status, TaskStatus.active);
        expect(tester.takeException(), isNull);
        await finish(tester);
      },
    );
  }

  testWidgets(
    'home edge and interior section swipes open Drawer and keep the current scope',
    (tester) async {
      await add('미지정 일정', due: today);
      await pumpApp(tester);
      expect(find.byKey(const ValueKey('drawer-settings')), findsNothing);
      await tester.dragFrom(const Offset(1, 300), const Offset(270, 0));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('drawer-settings')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('scope-list-kutodo:inbox')));
      await tester.pumpAndSettle();
      expect(row('미지정 일정'), findsOneWidget);
      // Rows own swipe actions; a section heading still opens the Drawer.
      await tester.flingFrom(
        tester.getTopLeft(find.byKey(const ValueKey('home-section-period'))) +
            const Offset(160, 16),
        const Offset(150, 0),
        1000,
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('drawer-settings')), findsOneWidget);
      expect(
        tester
            .widget<ListTile>(
              find.byKey(const ValueKey('scope-list-kutodo:inbox')),
            )
            .selected,
        isTrue,
      );
      await capture(tester, 'drawer-interior');
      await tester.dragFrom(const Offset(280, 300), const Offset(-270, 0));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('drawer-settings')), findsNothing);
      expect(row('미지정 일정'), findsOneWidget);
      expect((await tasks.getTasks()).single.status, TaskStatus.active);
      expect(find.byType(TaskDetailScreen), findsNothing);
      expect(tester.takeException(), isNull);
      await finish(tester);
    },
  );

  testWidgets(
    'wide Drawer gesture preserves vertical scrolling, row taps and checkbox actions',
    (tester) async {
      for (var i = 0; i < 18; i++) {
        await add('스크롤 일정 $i', due: today);
      }
      await pumpApp(tester);
      final homeScroll = find
          .ancestor(of: row('스크롤 일정 0'), matching: find.byType(Scrollable))
          .first;
      final scrollState = tester.state<ScrollableState>(homeScroll);
      // Predominantly vertical motion must stay with the task list.
      await tester.dragFrom(const Offset(180, 450), const Offset(12, -250));
      await tester.pumpAndSettle();
      expect(scrollState.position.pixels, greaterThan(0));
      expect(find.byKey(const ValueKey('drawer-settings')), findsNothing);
      await tester.ensureVisible(row('스크롤 일정 0'));
      await tester.pumpAndSettle();
      scrollState.position.jumpTo(0);
      await tester.pumpAndSettle();
      // A leftward swipe outside rows does not mutate or open a task.
      await tester.dragFrom(
        tester.getTopLeft(find.byKey(const ValueKey('home-section-period'))) +
            const Offset(220, 16),
        const Offset(-150, 0),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('drawer-settings')), findsNothing);
      expect(find.byType(TaskDetailScreen), findsNothing);
      expect((await tasks.getTaskById('스크롤 일정 0'))!.status, TaskStatus.active);
      await tester.tap(
        find.descendant(of: row('스크롤 일정 0'), matching: find.byType(Checkbox)),
      );
      await tester.pumpAndSettle();
      expect(
        (await tasks.getTaskById('스크롤 일정 0'))!.status,
        TaskStatus.completed,
      );
      expect(find.byKey(const ValueKey('drawer-settings')), findsNothing);
      await tester.tap(row('스크롤 일정 1'));
      await tester.pumpAndSettle();
      expect(find.byType(TaskDetailScreen), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect((await tasks.getTasks()).length, 17);
      expect(
        (await tasks.getTaskById('스크롤 일정 0'))!.status,
        TaskStatus.completed,
      );
      expect(tester.takeException(), isNull);
      await finish(tester);
    },
  );

  testWidgets(
    'swipes complete, reopen, delete, restore and confirm permanent deletion through existing handlers',
    (tester) async {
      await add('스와이프 일정', due: today, list: 'course');
      await pumpApp(tester);
      // A short drag resets without committing an action.
      await tester.dragFrom(
        tester.getCenter(row('스와이프 일정')),
        const Offset(40, 0),
      );
      await tester.pumpAndSettle();
      expect((await tasks.getTaskById('스와이프 일정'))!.status, TaskStatus.active);
      await swipeTask(tester, '스와이프 일정', toRight: true);
      expect(
        (await tasks.getTaskById('스와이프 일정'))!.status,
        TaskStatus.completed,
      );
      expect(notifications.cancelled, contains('스와이프 일정'));
      expect(find.byKey(const ValueKey('drawer-settings')), findsNothing);
      await chooseScope(tester, 'completed');
      await swipeTask(tester, '스와이프 일정', toRight: true, section: 'completed');
      expect((await tasks.getTaskById('스와이프 일정'))!.status, TaskStatus.active);
      await chooseScope(tester, 'period');
      await swipeTask(tester, '스와이프 일정', toRight: false);
      expect((await tasks.getTaskById('스와이프 일정'))!.status, TaskStatus.deleted);
      await chooseScope(tester, 'trash');
      await swipeTask(tester, '스와이프 일정', toRight: true, section: 'trash');
      expect((await tasks.getTaskById('스와이프 일정'))!.status, TaskStatus.active);
      expect((await tasks.getTaskById('스와이프 일정'))!.listId, 'course');
      await chooseScope(tester, 'period');
      await swipeTask(tester, '스와이프 일정', toRight: false);
      await chooseScope(tester, 'trash');
      await swipeTask(tester, '스와이프 일정', toRight: false, section: 'trash');
      expect(find.text('영구 삭제할까요?'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, '취소'));
      await tester.pumpAndSettle();
      expect((await tasks.getTaskById('스와이프 일정'))!.status, TaskStatus.deleted);
      await swipeTask(tester, '스와이프 일정', toRight: false, section: 'trash');
      await tester.tap(find.widgetWithText(FilledButton, '영구 삭제'));
      await tester.pumpAndSettle();
      expect(await tasks.getTaskById('스와이프 일정'), isNull);
      expect(tester.takeException(), isNull);
      await finish(tester);
    },
  );

  testWidgets(
    'settings context menu toggles notification and saves sliders on release without a page',
    (tester) async {
      await settings.saveSettings(
        (await settings.getSettings()).copyWith(
          hiddenTagIds: {'tag-b'},
          homeView: const HomeViewOptions(sort: HomeSort.newest),
        ),
      );
      await pumpApp(tester);
      await choosePeriod(tester, '이번 주');
      await openDrawer(tester);
      await tester.tap(find.byKey(const ValueKey('drawer-settings')));
      await tester.pumpAndSettle();
      final menu = find.byKey(const ValueKey('home-settings-menu'));
      expect(menu, findsOneWidget);
      expect(find.byType(BackButton), findsNothing);
      expect(find.byType(BottomSheet), findsNothing);
      expect(
        find
            .descendant(of: menu, matching: find.byType(Text))
            .evaluate()
            .map((e) => (e.widget as Text).data),
        ['스와이프', '알림', '마감 임박'],
      );
      for (final text in ['eCampus 가져오기', '로그인 세션', '마지막 가져오기', '세션/쿠키 정리']) {
        expect(find.text(text), findsNothing);
      }
      await tester.tap(
        find.byKey(const ValueKey('settings-notification-toggle')),
      );
      await tester.pumpAndSettle();
      expect((await settings.getSettings()).defaultNotificationEnabled, isTrue);
      expect(notifications.permissionRequests, 1);
      expect(
        find.descendant(of: menu, matching: find.text('알림 시점')),
        findsOneWidget,
      );
      await capture(tester, 'settings-menu');
      await tester.tap(find.text('알림 시점'));
      await tester.pumpAndSettle();
      final slider = find.byKey(const ValueKey('settings-value-slider'));
      final box = tester.getRect(slider);
      final gesture = await tester.startGesture(box.center);
      await gesture.moveTo(Offset(box.right - 24, box.center.dy));
      await tester.pump();
      expect((await settings.getSettings()).defaultNotificationDays, 60);
      await gesture.up();
      await tester.pumpAndSettle();
      expect((await settings.getSettings()).defaultNotificationDays, 4320);
      expect(find.text('마감 3일 전'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(FilledButton),
        ),
        findsNothing,
      );
      await capture(tester, 'notification-time');
      await dismissSheet(tester);
      await tester.tap(find.byKey(const ValueKey('drawer-settings')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('home-settings-menu')),
          matching: find.text('마감 임박'),
        ),
      );
      await tester.pumpAndSettle();
      final urgent = tester.getRect(slider);
      await tester.tapAt(Offset(urgent.right - 24, urgent.center.dy));
      await tester.pumpAndSettle();
      expect((await settings.getSettings()).urgentDueDays, 14);
      await capture(tester, 'urgent-days');
      await dismissSheet(tester);
      await restart(tester);
      final saved = await settings.getSettings();
      expect(saved.defaultNotificationDays, 4320);
      expect(saved.urgentDueDays, 14);
      expect(saved.homeView.sort, HomeSort.newest);
      expect(saved.homePeriod.mode, HomePeriod.week);
      expect(saved.hiddenTagIds, {'tag-b'});
      expect(tester.takeException(), isNull);
      await finish(tester);
    },
  );

  testWidgets(
    'automatic settings errors keep prior values and retry from their controls',
    (tester) async {
      final failing = _FailingSwipeSettings(database: database);
      settings = failing;
      await pumpApp(tester);
      await openDrawer(tester);
      await tester.tap(find.byKey(const ValueKey('drawer-settings')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('settings-notification-toggle')),
      );
      await tester.pumpAndSettle();
      expect(
        (await settings.getSettings()).defaultNotificationEnabled,
        isFalse,
      );
      expect(find.text('알림 시점'), findsNothing);
      failing.failSave = false;
      await tester.tap(
        find.byKey(const ValueKey('settings-notification-toggle')),
      );
      await tester.pumpAndSettle();
      expect((await settings.getSettings()).defaultNotificationEnabled, isTrue);
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('home-settings-menu')),
          matching: find.text('마감 임박'),
        ),
      );
      await tester.pumpAndSettle();
      failing.failSave = true;
      final slider = find.byKey(const ValueKey('settings-value-slider'));
      final box = tester.getRect(slider);
      await tester.tapAt(Offset(box.right - 24, box.center.dy));
      await tester.pumpAndSettle();
      expect((await settings.getSettings()).urgentDueDays, 3);
      expect(find.text('3일 이내'), findsOneWidget);
      expect(find.text('설정을 저장하지 못했습니다. 다시 설정해주세요.'), findsOneWidget);
      failing.failSave = false;
      final retryBox = tester.getRect(slider);
      await tester.tapAt(Offset(retryBox.right - 24, retryBox.center.dy));
      await tester.pumpAndSettle();
      expect((await settings.getSettings()).urgentDueDays, 14);
      expect(tester.takeException(), isNull);
      await finish(tester);
    },
  );

  testWidgets(
    'swipe settings immediately save four mappings and survive restart without action buttons',
    (tester) async {
      tester.view.physicalSize = const Size(360, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await settings.saveSettings(
        (await settings.getSettings()).copyWith(
          urgentDueDays: 7,
          hiddenTagIds: {'tag-b'},
          homeView: const HomeViewOptions(sort: HomeSort.newest),
        ),
      );
      await add('설정 일정', due: today);
      await pumpApp(tester);
      await openSwipeSettings(tester);
      expect(
        tester.widget<Text>(find.text('스와이프 동작')).textAlign,
        TextAlign.center,
      );
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('할 일'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('휴지통'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(TextButton),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(FilledButton),
        ),
        findsNothing,
      );
      expect(find.byIcon(Icons.arrow_forward_rounded), findsNWidgets(2));
      expect(find.byIcon(Icons.arrow_back_rounded), findsNWidgets(2));
      for (final id in ['right', 'left']) {
        final field = find.byKey(ValueKey('swipe-setting-$id'));
        expect(
          tester
              .widget<DropdownButton<TaskSwipeAction>>(
                find.descendant(
                  of: field,
                  matching: find.byType(DropdownButton<TaskSwipeAction>),
                ),
              )
              .items!
              .map((i) => i.value)
              .toList(),
          normalSwipeActions,
        );
      }
      await chooseSwipe(tester, 'right', TaskSwipeAction.edit);
      await chooseSwipe(tester, 'left', TaskSwipeAction.complete);
      await chooseSwipe(
        tester,
        'trash-right',
        TaskSwipeAction.deletePermanently,
      );
      await chooseSwipe(tester, 'trash-left', TaskSwipeAction.restore);
      final trashField = tester.widget<DropdownButton<TaskSwipeAction>>(
        find.descendant(
          of: find.byKey(const ValueKey('swipe-setting-trash-left')),
          matching: find.byType(DropdownButton<TaskSwipeAction>),
        ),
      );
      expect(trashField.items!.map((i) => i.value).toList(), trashSwipeActions);
      await capture(tester, 'swipe-settings');
      final saved = await settings.getSettings();
      expect(
        saved.taskSwipes.encode(),
        const TaskSwipeOptions(
          right: TaskSwipeAction.edit,
          left: TaskSwipeAction.complete,
          trashRight: TaskSwipeAction.deletePermanently,
          trashLeft: TaskSwipeAction.restore,
        ).encode(),
      );
      expect(saved.urgentDueDays, 7);
      expect(saved.hiddenTagIds, {'tag-b'});
      expect(saved.homeView.sort, HomeSort.newest);
      await restart(tester);
      await swipeTask(tester, '설정 일정', toRight: true);
      expect(find.byType(TaskDetailScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('drawer-settings')), findsNothing);
      await tester.enterText(find.byType(TextField).first, '스와이프로 편집');
      await tester.tap(find.byTooltip('작업 상세 닫기'));
      await tester.pumpAndSettle();
      expect((await tasks.getTaskById('설정 일정'))!.title, '스와이프로 편집');
      await swipeTask(tester, '설정 일정', toRight: false);
      expect((await tasks.getTaskById('설정 일정'))!.status, TaskStatus.completed);
      expect(tester.takeException(), isNull);
      await finish(tester);
    },
  );

  testWidgets('failed swipe retains the task row and can be retried', (
    tester,
  ) async {
    final failing = _FailingSwipeTasks(database: database);
    tasks = failing;
    await add('실패 스와이프', due: today);
    await pumpApp(tester);
    await swipeTask(tester, '실패 스와이프', toRight: false);
    expect((await tasks.getTaskById('실패 스와이프'))!.status, TaskStatus.active);
    expect(row('실패 스와이프'), findsOneWidget);
    expect(notifications.cancelled, isEmpty);
    expect(find.textContaining('스와이프 작업 처리 중 오류'), findsWidgets);
    failing.failDelete = false;
    await swipeTask(tester, '실패 스와이프', toRight: false);
    expect((await tasks.getTaskById('실패 스와이프'))!.status, TaskStatus.deleted);
    expect(tester.takeException(), isNull);
    await finish(tester);
  });

  testWidgets(
    'failed automatic swipe save keeps the old choice and retries without buttons',
    (tester) async {
      final failing = _FailingSwipeSettings(database: database);
      settings = failing;
      await pumpApp(tester);
      await openSwipeSettings(tester);
      await chooseSwipe(tester, 'right', TaskSwipeAction.edit);
      expect(find.text('설정을 저장하지 못했습니다. 다시 선택해주세요.'), findsOneWidget);
      expect(
        (await settings.getSettings()).taskSwipes.right,
        TaskSwipeAction.complete,
      );
      final dropdown = find.descendant(
        of: find.byKey(const ValueKey('swipe-setting-right')),
        matching: find.byType(DropdownButton<TaskSwipeAction>),
      );
      expect(
        tester.widget<DropdownButton<TaskSwipeAction>>(dropdown).value,
        TaskSwipeAction.complete,
      );
      failing.failSave = false;
      await chooseSwipe(tester, 'right', TaskSwipeAction.edit);
      expect(
        (await settings.getSettings()).taskSwipes.right,
        TaskSwipeAction.edit,
      );
      expect(find.byKey(const ValueKey('swipe-setting-right')), findsOneWidget);
      await dismissSheet(tester);
      expect(find.byKey(const ValueKey('swipe-setting-right')), findsNothing);
      expect(tester.takeException(), isNull);
      await finish(tester);
    },
  );

  testWidgets(
    'selected Drawer row does not paint behind the fixed settings footer',
    (tester) async {
      for (var i = 0; i < 16; i++) {
        await tags.createTag(
          Tag(
            id: 'extra-$i',
            name: '태그 $i',
            color: '#1262D6',
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
      await pumpApp(tester);
      await tester.binding.setSurfaceSize(const Size(360, 650));
      await tester.pumpAndSettle();
      final trash = find.byKey(const ValueKey('scope-trash-'));
      Future<void> showTrash() async {
        await openDrawer(tester);
        await tester.scrollUntilVisible(
          trash,
          250,
          scrollable: find
              .descendant(
                of: find.byType(Drawer),
                matching: find.byType(Scrollable),
              )
              .last,
        );
        await tester.ensureVisible(trash);
        await tester.pumpAndSettle();
      }

      await showTrash();
      await tester.tap(trash);
      await tester.pumpAndSettle();
      await showTrash();
      expect(tester.widget<ListTile>(trash).selected, isTrue);
      final footer = tester.getRect(
        find.byKey(const ValueKey('drawer-settings')),
      );
      final drawer = tester.getRect(find.byType(Drawer));
      final x = drawer.right - 24;
      Future<Color> pixel(Offset point) async {
        return (await tester.runAsync(() async {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('capture-home')),
          );
          final image = await boundary.toImage(pixelRatio: 1);
          final bytes = (await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
          final offset =
              (point.dy.floor() * image.width + point.dx.floor()) * 4;
          final color = Color.fromARGB(
            bytes.getUint8(offset + 3),
            bytes.getUint8(offset),
            bytes.getUint8(offset + 1),
            bytes.getUint8(offset + 2),
          );
          image.dispose();
          return color;
        }))!;
      }

      final background = await pixel(Offset(x, drawer.top + 16));
      await tester.drag(
        find
            .descendant(
              of: find.byType(Drawer),
              matching: find.byType(Scrollable),
            )
            .last,
        const Offset(0, 80),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byKey(const ValueKey('drawer-settings'))),
        footer,
      );
      expect(await pixel(Offset(x, footer.center.dy)), background);
      await capture(tester, 'drawer-footer');
      await tester.tap(find.byKey(const ValueKey('drawer-settings')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('home-settings-menu')), findsOneWidget);
      expect(find.text('세션/쿠키 정리'), findsNothing);
      expect(tester.takeException(), isNull);
      await finish(tester);
    },
  );

  testWidgets(
    'folders only expand lists; list scopes compose with periods and retain selection',
    (tester) async {
      await add('학교 과제', due: today, list: 'course', tagIds: ['tag-a']);
      await add('개인 일정', due: today, tagIds: ['tag-b']);
      await pumpApp(tester);
      await openDrawer(tester);
      final folder = find.byKey(const ValueKey('drawer-folder-school'));
      final course = find.byKey(const ValueKey('scope-list-course'));
      expect(course, findsNothing);
      await tester.tap(find.descendant(of: folder, matching: find.text('학교')));
      await tester.pumpAndSettle();
      expect(course, findsOneWidget);
      expect(find.byType(Drawer), findsOneWidget);
      expect(
        tester
            .widget<ListTile>(find.byKey(const ValueKey('scope-period-')))
            .selected,
        isTrue,
      );
      expect(row('학교 과제'), findsOneWidget);
      expect(row('개인 일정'), findsOneWidget);
      await tester.tap(find.descendant(of: folder, matching: find.text('학교')));
      await tester.pumpAndSettle();
      expect(course, findsNothing);
      expect(
        tester
            .widget<ListTile>(find.byKey(const ValueKey('scope-period-')))
            .selected,
        isTrue,
      );
      await tester.tap(find.descendant(of: folder, matching: find.text('학교')));
      await tester.pumpAndSettle();
      await tester.tap(course);
      await tester.pumpAndSettle();
      expect(row('학교 과제'), findsOneWidget);
      expect(row('개인 일정'), findsNothing);
      await choosePeriod(tester, '이번 주');
      expect(row('학교 과제'), findsOneWidget);
      await openDrawer(tester);
      expect(
        tester
            .widget<ListTile>(find.byKey(const ValueKey('scope-list-course')))
            .selected,
        isTrue,
      );
      await capture(tester, 'drawer');
      await tester.tap(find.byKey(const ValueKey('scope-tag-tag-b')));
      await tester.pumpAndSettle();
      expect(row('학교 과제'), findsNothing);
      expect(row('개인 일정'), findsOneWidget);
      expect(find.text('이번 주'), findsNWidgets(2));
      await chooseScope(tester, 'list', inboxListId);
      expect(row('개인 일정'), findsOneWidget);
      await chooseScope(tester, 'period');
      expect(row('학교 과제'), findsOneWidget);
      expect(row('개인 일정'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await finish(tester);
    },
  );

  testWidgets(
    'Drawer headings create metadata through existing management handlers',
    (tester) async {
      await pumpApp(tester);
      await openDrawer(tester);
      expect(find.text('미지정'), findsOneWidget);
      expect(find.text('수집함'), findsNothing);
      expect(find.text('목록'), findsOneWidget);
      expect(find.text('기타'), findsOneWidget);
      expect(find.text('보관'), findsNothing);
      final actionX = [
        for (final label in ['목록 숨김', '폴더 추가', '목록 추가'])
          tester.getCenter(find.byTooltip(label)).dx,
      ];
      expect(actionX, orderedEquals([...actionX]..sort()));
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('scope-completed-')),
          matching: find.byIcon(Icons.check_box_outlined),
        ),
        findsOneWidget,
      );
      await capture(tester, 'drawer-actions');
      await tester.tap(find.byTooltip('폴더 추가'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '개인 폴더');
      await tester.tap(find.widgetWithText(FilledButton, '저장'));
      await tester.pumpAndSettle();
      final group = (await lists.getGroups()).singleWhere(
        (g) => g.name == '개인 폴더',
      );
      expect(find.byType(Drawer), findsOneWidget);
      expect(find.byKey(ValueKey('drawer-folder-${group.id}')), findsOneWidget);
      await tester.tap(find.byTooltip('목록 추가'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '개인 목록');
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('폴더 밖'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('개인 폴더').last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '저장'));
      await tester.pumpAndSettle();
      final list = (await lists.getFolders()).singleWhere(
        (l) => l.name == '개인 목록',
      );
      expect(list.groupId, group.id);
      await tester.tap(
        find.descendant(
          of: find.byKey(ValueKey('drawer-folder-${group.id}')),
          matching: find.text('개인 폴더'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey('scope-list-${list.id}')), findsOneWidget);
      await tester.ensureVisible(find.byTooltip('태그 추가'));
      await tester.tap(find.byTooltip('태그 추가'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '새 태그');
      await tester.tap(find.widgetWithText(FilledButton, '저장'));
      await tester.pumpAndSettle();
      expect((await tags.getTags()).any((t) => t.name == '새 태그'), isTrue);
      expect(await tasks.getTasks(), isEmpty);
      expect(find.byType(Drawer), findsOneWidget);
      expect(tester.takeException(), isNull);
      await finish(tester);
    },
  );

  testWidgets(
    'Inbox stays first in Drawer despite list order and folder expansion',
    (tester) async {
      await (database.update(database.folders)
            ..where((t) => t.id.equals(inboxListId)))
          .write(const db.FoldersCompanion(sortOrder: Value(999)));
      await lists.createFolder(
        Folder(
          id: 'root-list',
          name: '개인 목록',
          sortOrder: 0,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await pumpApp(tester);
      await openDrawer(tester);
      final inbox = find.byKey(const ValueKey('scope-list-kutodo:inbox'));
      final group = find.byKey(const ValueKey('drawer-folder-school'));
      final root = find.byKey(const ValueKey('scope-list-root-list'));
      expect(inbox, findsOneWidget);
      expect(
        tester.getTopLeft(inbox).dy,
        lessThan(tester.getTopLeft(group).dy),
      );
      expect(tester.getTopLeft(inbox).dy, lessThan(tester.getTopLeft(root).dy));
      await tester.tap(group);
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(inbox).dy,
        lessThan(
          tester.getTopLeft(find.byKey(const ValueKey('scope-list-course'))).dy,
        ),
      );
      await tester.tap(inbox);
      await tester.pumpAndSettle();
      await restart(tester);
      await openDrawer(tester);
      expect(
        tester.getTopLeft(inbox).dy,
        lessThan(tester.getTopLeft(group).dy),
      );
      await finish(tester);
    },
  );

  testWidgets(
    'separate visibility menus contain names and eyes only, persist changes and omit Inbox',
    (tester) async {
      await settings.saveSettings(
        (await settings.getSettings()).copyWith(
          hiddenFolderIds: {'course', inboxListId},
          hiddenTagIds: {'tag-a'},
          urgentDueDays: 7,
          homeView: const HomeViewOptions(sort: HomeSort.dueLate),
        ),
      );
      await add('숨긴 목록의 과제', due: today, list: 'course', tagIds: ['tag-a']);
      await pumpApp(tester);
      await openDrawer(tester);
      await tester.tap(find.byKey(const ValueKey('drawer-folder-school')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('scope-list-course')), findsNothing);
      expect(find.byKey(const ValueKey('scope-tag-tag-a')), findsNothing);
      expect(
        find.byKey(const ValueKey('scope-list-kutodo:inbox')),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('목록 숨김'));
      await tester.pumpAndSettle();
      final listMenu = find.byKey(const ValueKey('visibility-menu-list'));
      final listRow = find.byKey(const ValueKey('visibility-list-course'));
      final tagRow = find.byKey(const ValueKey('visibility-tag-tag-a'));
      expect(listMenu, findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.byType(SwitchListTile), findsNothing);
      expect(
        find.byKey(const ValueKey('visibility-list-kutodo:inbox')),
        findsNothing,
      );
      expect(tagRow, findsNothing);
      expect(
        find.descendant(of: listMenu, matching: find.text('학교')),
        findsNothing,
      );
      expect(tester.getSize(listMenu).width, inInclusiveRange(152.0, 208.0));
      expect(
        find.descendant(of: listRow, matching: find.byType(Text)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: listRow, matching: find.byType(IconButton)),
        findsOneWidget,
      );
      final nameRect = tester.getRect(
        find.descendant(of: listRow, matching: find.text('운영체제')),
      );
      final eyeRect = tester.getRect(
        find.byKey(const ValueKey('visibility-toggle-course')),
      );
      expect(nameRect.left, greaterThan(tester.getRect(listMenu).left));
      expect(eyeRect.left, greaterThan(nameRect.right));
      expect(nameRect.center.dy, closeTo(eyeRect.center.dy, 1));
      expect(
        find.descendant(
          of: listRow,
          matching: find.byIcon(Icons.visibility_off_outlined),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('visibility-toggle-course')));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: listRow,
          matching: find.byIcon(Icons.visibility_outlined),
        ),
        findsOneWidget,
      );
      await capture(tester, 'list-visibility');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('태그 숨김'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('visibility-menu-tag')), findsOneWidget);
      expect(listRow, findsNothing);
      await tester.tap(find.byKey(const ValueKey('visibility-toggle-tag-a')));
      await tester.pumpAndSettle();
      await capture(tester, 'tag-visibility');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('scope-list-course')), findsOneWidget);
      expect(find.byKey(const ValueKey('scope-tag-tag-a')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('scope-list-course')));
      await tester.pumpAndSettle();
      await openDrawer(tester);
      await tester.tap(find.byTooltip('목록 숨김'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('visibility-toggle-course')));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('태그 숨김'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('visibility-toggle-tag-a')));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('scope-list-course')), findsNothing);
      expect(find.byKey(const ValueKey('scope-tag-tag-a')), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(row('숨긴 목록의 과제'), findsOneWidget);
      final saved = await settings.getSettings();
      expect(saved.hiddenFolderIds, {'course', inboxListId});
      expect(saved.hiddenTagIds, {'tag-a'});
      expect(saved.urgentDueDays, 7);
      expect(saved.homeView.sort, HomeSort.dueLate);
      expect((await tasks.getTasks()).single.listId, 'course');
      await restart(tester);
      await openDrawer(tester);
      await tester.tap(find.byTooltip('목록 숨김'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: listRow,
          matching: find.byIcon(Icons.visibility_off_outlined),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await finish(tester);
    },
  );

  testWidgets(
    'visibility save failure keeps the eye unchanged and retries without conversion',
    (tester) async {
      final failing = _FailingSwipeSettings(database: database);
      settings = failing;
      await pumpApp(tester);
      await openDrawer(tester);
      await tester.tap(find.byTooltip('목록 숨김'));
      await tester.pumpAndSettle();
      final row = find.byKey(const ValueKey('visibility-list-course'));
      await tester.tap(find.byKey(const ValueKey('visibility-toggle-course')));
      await tester.pumpAndSettle();
      expect(find.text('숨김 설정을 저장하지 못했습니다. 다시 시도해주세요.'), findsOneWidget);
      expect(
        find.descendant(
          of: row,
          matching: find.byIcon(Icons.visibility_outlined),
        ),
        findsOneWidget,
      );
      expect((await settings.getSettings()).hiddenFolderIds, isEmpty);
      failing.failSave = false;
      await tester.tap(find.byKey(const ValueKey('visibility-toggle-course')));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: row,
          matching: find.byIcon(Icons.visibility_off_outlined),
        ),
        findsOneWidget,
      );
      expect((await settings.getSettings()).hiddenFolderIds, {'course'});
      expect(tester.takeException(), isNull);
      await finish(tester);
    },
  );

  testWidgets(
    'folder long press reuses edit and preselects parent for a new list',
    (tester) async {
      await pumpApp(tester);
      await openDrawer(tester);
      final folder = find.byKey(const ValueKey('drawer-folder-school'));
      await tester.longPress(folder);
      await tester.pumpAndSettle();
      expect(find.text('폴더 편집'), findsOneWidget);
      await tester.tap(find.text('폴더 편집'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, '학교'), '학교 폴더');
      await tester.tap(find.widgetWithText(FilledButton, '저장'));
      await tester.pumpAndSettle();
      expect((await lists.getGroups()).single.name, '학교 폴더');
      expect(find.byType(Drawer), findsOneWidget);
      await tester.longPress(folder);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, '목록 추가'));
      await tester.pumpAndSettle();
      expect(find.text('학교 폴더').last, findsOneWidget);
      await tester.enterText(find.byType(TextField).first, '자료구조');
      await tester.tap(find.widgetWithText(FilledButton, '저장'));
      await tester.pumpAndSettle();
      expect(
        (await lists.getFolders()).singleWhere((l) => l.name == '자료구조').groupId,
        'school',
      );
      expect(await tasks.getTasks(), isEmpty);
      expect(
        tester
            .widget<ListTile>(find.byKey(const ValueKey('scope-period-')))
            .selected,
        isTrue,
      );
      expect(tester.takeException(), isNull);
      await finish(tester);
    },
  );

  testWidgets(
    'list long press edits that list and quick adds into it without triggering folder actions',
    (tester) async {
      await pumpApp(tester);
      await openDrawer(tester);
      await tester.tap(find.byKey(const ValueKey('drawer-folder-school')));
      await tester.pumpAndSettle();
      final list = find.byKey(const ValueKey('scope-list-course'));
      await tester.longPress(list);
      await tester.pumpAndSettle();
      expect(find.text('폴더 편집'), findsNothing);
      await tester.tap(find.text('목록 편집'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, '운영체제'), 'OS');
      await tester.tap(find.widgetWithText(FilledButton, '저장'));
      await tester.pumpAndSettle();
      expect(
        (await lists.getFolders()).singleWhere((l) => l.id == 'course').name,
        'OS',
      );
      await tester.longPress(list);
      await tester.pumpAndSettle();
      await capture(tester, 'list-actions');
      await tester.tap(find.text('할 일 추가'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilterChip>(find.widgetWithText(FilterChip, 'OS'))
            .selected,
        isTrue,
      );
      await tester.tap(find.byTooltip('빠른 추가 닫기'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(await tasks.getTasks(), isEmpty);
      await tester.longPress(list);
      await tester.pumpAndSettle();
      await tester.tap(find.text('할 일 추가'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '목록에서 추가');
      await tester.tap(find.widgetWithText(FilledButton, '추가'));
      await tester.pumpAndSettle();
      final created = (await tasks.getTasks()).single;
      expect(created.listId, 'course');
      expect(created.tagIds, isEmpty);
      expect(created.origin, TaskOrigin.personal);
      expect(tester.takeException(), isNull);
      await finish(tester);
    },
  );

  testWidgets(
    'tag long press edits that tag and preserves it through detailed create',
    (tester) async {
      await pumpApp(tester);
      await openDrawer(tester);
      final tag = find.byKey(const ValueKey('scope-tag-tag-a'));
      await tester.ensureVisible(tag);
      await tester.longPress(tag);
      await tester.pumpAndSettle();
      await tester.tap(find.text('태그 편집'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, '과제'), '학교 과제');
      await tester.tap(find.widgetWithText(FilledButton, '저장'));
      await tester.pumpAndSettle();
      expect(
        (await tags.getTags()).singleWhere((t) => t.id == 'tag-a').name,
        '학교 과제',
      );
      await tester.ensureVisible(tag);
      await tester.longPress(tag);
      await tester.pumpAndSettle();
      await tester.tap(find.text('할 일 추가'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilterChip>(find.widgetWithText(FilterChip, '학교 과제'))
            .selected,
        isTrue,
      );
      await tester.enterText(find.byType(TextField), '태그에서 추가');
      await tester.tap(find.text('상세 설정'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TaskCreateScreen>(find.byType(TaskCreateScreen)).quickAdd,
        isFalse,
      );
      await tester.tap(find.text('저장').first);
      await tester.pumpAndSettle();
      final created = (await tasks.getTasks()).single;
      expect(created.listId, inboxListId);
      expect(created.tagIds, ['tag-a']);
      expect(find.byType(TaskCreateScreen), findsNothing);
      expect(tester.takeException(), isNull);
      await finish(tester);
    },
  );

  testWidgets(
    'all-date option reveals future tasks and navigation names follow the selected period',
    (tester) async {
      await add(
        '먼 마감 일정',
        due: today.add(const Duration(days: 40)),
        list: 'course',
      );
      await pumpApp(tester);
      expect(row('먼 마감 일정'), findsNothing);
      expect((await tasks.getTasks()).length, 1);
      await chooseScope(tester, 'all');
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('home-period')),
          matching: find.text('전체'),
        ),
        findsWidgets,
      );
      expect(row('먼 마감 일정'), findsOneWidget);
      await openDrawer(tester);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('scope-all-')),
          matching: find.text('전체'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('scope-period-')));
      await tester.pumpAndSettle();
      await capture(tester, 'all-dates');
      await choosePeriod(tester, '오늘');
      expect(row('먼 마감 일정'), findsNothing);
      for (final label in ['오늘', '이번 주', '이번 달']) {
        await choosePeriod(tester, label);
        await openDrawer(tester);
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('scope-period-')),
            matching: find.text(label),
          ),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const ValueKey('scope-period-')));
        await tester.pumpAndSettle();
      }
      expect((await tasks.getTasks()).length, 1);
      expect(tester.takeException(), isNull);
      await finish(tester);
    },
  );

  for (final endDay in [12, 14]) {
    testWidgets(
      'custom period includes both date boundaries and supports a same-day range: $endDay',
      (tester) async {
        await add('구간 시작', due: DateTime(2030, 11, 12), list: 'course');
        await add(
          '구간 끝',
          due: DateTime(2030, 11, endDay, 23, 59, 59, 999),
          list: 'course',
        );
        await add(
          '구간 이전',
          due: DateTime(2030, 11, 11, 23, 59, 59),
          list: 'course',
        );
        await add('구간 이후', due: DateTime(2030, 11, endDay + 1), list: 'course');
        await pumpApp(tester);
        await chooseScope(tester, 'list', 'course');
        await tester.tap(find.byKey(const ValueKey('home-period')));
        await tester.pumpAndSettle();
        final options = tester
            .widgetList<ListTile>(
              find.descendant(
                of: find.byType(BottomSheet),
                matching: find.byType(ListTile),
              ),
            )
            .map((tile) => (tile.title! as Text).data)
            .toList();
        expect(options, ['오늘', '이번 주', '이번 달', '기간 선택']);
        await tester.tap(find.text('기간 선택').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('날짜 구간'));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.edit_outlined));
        await tester.pumpAndSettle();
        final fields = find.byType(TextField);
        await tester.enterText(fields.at(0), '2030. 11. 12.');
        await tester.enterText(fields.at(1), '2030. 11. $endDay.');
        await tester.tap(find.text('적용').last);
        await tester.pumpAndSettle();
        expect(row('구간 시작'), findsOneWidget);
        expect(row('구간 끝'), findsOneWidget);
        expect(row('구간 이전'), findsNothing);
        expect(row('구간 이후'), findsNothing);
        final label = endDay == 12 ? '2030년 11월 12일' : '2030.11.12 ~ 11.14';
        expect(find.text(label), findsNWidgets(2));
        await capture(tester, endDay == 12 ? 'same-day' : 'range');
        await tester.tap(find.byKey(const ValueKey('nav-calendar')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('nav-home')));
        await tester.pumpAndSettle();
        expect(row('구간 끝'), findsOneWidget);
        expect(find.text(label), findsNWidgets(2));
        await restart(tester);
        expect(find.text(label), findsNWidgets(2));
        expect(row('구간 시작'), findsOneWidget);
        expect(row('구간 끝'), findsOneWidget);
        expect(row('구간 이전'), findsNothing);
        expect(row('구간 이후'), findsNothing);
        expect(tester.takeException(), isNull);
        await finish(tester);
      },
    );
  }

  testWidgets('canceling custom period selection retains the previous period', (
    tester,
  ) async {
    await pumpApp(tester);
    await choosePeriod(tester, '이번 주');
    await choosePeriod(tester, '기간 선택');
    await dismissSheet(tester);
    expect(find.text('이번 주'), findsNWidgets(2));
    await choosePeriod(tester, '기간 선택');
    await tester.tap(find.text('날짜 구간'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('이번 주'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
    await finish(tester);
  });

  testWidgets('month and single custom date persist across restart', (
    tester,
  ) async {
    await add('선택 날짜 일정', due: DateTime(2030, 11, 12, 23, 59));
    await pumpApp(tester);
    await choosePeriod(tester, '이번 달');
    await restart(tester);
    expect(find.text('이번 달'), findsNWidgets(2));
    expect(row('선택 날짜 일정'), findsNothing);
    await choosePeriod(tester, '기간 선택');
    await tester.tap(find.text('단일 날짜'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '2030. 11. 12.');
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.text('2030년 11월 12일'), findsNWidgets(2));
    expect(row('선택 날짜 일정'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('nav-calendar')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('nav-home')));
    await tester.pumpAndSettle();
    expect(find.text('2030년 11월 12일'), findsNWidgets(2));
    await restart(tester);
    expect(find.text('2030년 11월 12일'), findsNWidgets(2));
    expect(row('선택 날짜 일정'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await finish(tester);
  });

  testWidgets(
    'sort and filters apply immediately; unsaved changes disappear on restart',
    (tester) async {
      await add(
        '먼 마감',
        due: today,
        priority: TaskPriority.low,
        tagIds: ['tag-b'],
      );
      await add(
        '빠른 마감',
        due: DateTime(today.year, today.month, today.day, 23, 59, 58),
        priority: TaskPriority.high,
        tagIds: ['tag-a'],
      );
      await pumpApp(tester);
      await adjust(tester);
      await tester.tap(find.text('마감 빠른 순'));
      await tester.pumpAndSettle();
      await dismissSheet(tester);
      expect(
        tester.getTopLeft(row('빠른 마감')).dy,
        lessThan(tester.getTopLeft(row('먼 마감')).dy),
      );
      await adjust(tester);
      await tester.tap(find.text('마감 늦은 순'));
      await tester.pumpAndSettle();
      await dismissSheet(tester);
      expect(
        tester.getTopLeft(row('먼 마감')).dy,
        lessThan(tester.getTopLeft(row('빠른 마감')).dy),
      );
      await adjust(tester);
      await tester.tap(find.widgetWithText(FilterChip, '높음'));
      await tester.ensureVisible(find.widgetWithText(FilterChip, '#과제'));
      await tester.tap(find.widgetWithText(FilterChip, '#과제'));
      await tester.pumpAndSettle();
      await dismissSheet(tester);
      expect(row('빠른 마감'), findsOneWidget);
      expect(row('먼 마감'), findsNothing);
      expect((await settings.getSettings()).homeView.isDefault, isTrue);
      await restart(tester);
      expect(row('먼 마감'), findsOneWidget);
      expect(row('빠른 마감'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await finish(tester);
    },
  );

  testWidgets(
    'saved view survives restart; reset is immediate and only saved on request',
    (tester) async {
      await add(
        '중요 과제',
        due: today,
        priority: TaskPriority.high,
        tagIds: ['tag-a'],
      );
      await add('일반 일정', due: today, priority: TaskPriority.low);
      await pumpApp(tester);
      await choosePeriod(tester, '이번 주');
      await adjust(tester);
      await tester.tap(find.widgetWithText(ChoiceChip, '우선순위'));
      await tester.tap(find.widgetWithText(FilterChip, '높음'));
      await capture(tester, 'view-options');
      await tester.tap(find.widgetWithText(FilledButton, '저장'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(FilledButton, '저장'), findsNothing);
      expect((await settings.getSettings()).homeView.sort, HomeSort.priority);
      expect((await settings.getSettings()).homeView.priorities, {
        TaskPriority.high,
      });
      await restart(tester);
      expect(find.text('이번 주'), findsNWidgets(2));
      expect(row('일반 일정'), findsNothing);
      expect(row('중요 과제'), findsOneWidget);
      await adjust(tester);
      await tester.tap(find.text('기본값 초기화'));
      await tester.pumpAndSettle();
      await dismissSheet(tester);
      expect(row('일반 일정'), findsOneWidget);
      await restart(tester);
      expect(row('일반 일정'), findsNothing);
      await adjust(tester);
      await tester.tap(find.text('기본값 초기화'));
      await tester.tap(find.widgetWithText(FilledButton, '저장'));
      await tester.pumpAndSettle();
      await restart(tester);
      expect(row('일반 일정'), findsOneWidget);
      expect((await settings.getSettings()).homeView.isDefault, isTrue);
      expect(tester.takeException(), isNull);
      await finish(tester);
    },
  );

  testWidgets(
    'period changes affect date and completion sections but keep urgent and overdue anchored to now',
    (tester) async {
      final future = DateTime(now.year + 1, 1, 15, 12);
      await add(
        '현재 기준 임박',
        due: DateTime(now.year, now.month, now.day + 2, 23, 59),
        list: 'course',
      );
      await add(
        '현재 기준 지남',
        due: DateTime(now.year, now.month, now.day - 2, 23, 59),
        list: 'course',
      );
      await add('미래 선택 마감', due: future, list: 'course');
      await add('마감 없음 유지', list: 'course');
      await add('오늘 완료한 미래 마감', due: future, list: 'course', completed: true);
      await add('다른 목록 임박', due: DateTime(now.year, now.month, now.day + 1));
      await add('다른 목록 지남', due: DateTime(now.year, now.month, now.day - 1));
      await pumpApp(tester);
      await chooseScope(tester, 'list', 'course');
      void checkCurrentAnchors() {
        expect(row('현재 기준 임박', 'urgent'), findsOneWidget);
        expect(row('현재 기준 지남', 'overdue'), findsOneWidget);
        expect(row('미래 선택 마감', 'urgent'), findsNothing);
        expect(row('미래 선택 마감', 'overdue'), findsNothing);
        expect(row('다른 목록 임박', 'urgent'), findsNothing);
        expect(row('다른 목록 지남', 'overdue'), findsNothing);
        expect(row('마감 없음 유지'), findsOneWidget);
      }

      for (final period in ['오늘', '이번 주', '이번 달']) {
        await choosePeriod(tester, period);
        checkCurrentAnchors();
        expect(row('오늘 완료한 미래 마감', 'completed'), findsOneWidget);
        expect(row('미래 선택 마감'), period == '전체' ? findsOneWidget : findsNothing);
      }
      await choosePeriod(tester, '기간 선택');
      await tester.tap(find.text('단일 날짜'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField),
        '${future.year}. ${future.month}. ${future.day}.',
      );
      await tester.tap(find.text('확인').last);
      await tester.pumpAndSettle();
      checkCurrentAnchors();
      expect(row('미래 선택 마감'), findsOneWidget);
      // Completed-at, rather than the future due date, controls this section.
      expect(row('오늘 완료한 미래 마감', 'completed'), findsNothing);
      await choosePeriod(tester, '기간 선택');
      await tester.tap(find.text('날짜 구간'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();
      final end = DateTime(future.year, future.month, future.day + 2);
      final fields = find.byType(TextField);
      await tester.enterText(
        fields.at(0),
        '${future.year}. ${future.month}. ${future.day}.',
      );
      await tester.enterText(
        fields.at(1),
        '${end.year}. ${end.month}. ${end.day}.',
      );
      await tester.tap(find.text('적용').last);
      await tester.pumpAndSettle();
      checkCurrentAnchors();
      expect(row('미래 선택 마감'), findsOneWidget);
      expect(row('오늘 완료한 미래 마감', 'completed'), findsNothing);
      expect(tester.takeException(), isNull);
      await finish(tester);
    },
  );

  testWidgets(
    'completed overdue and urgent stay scoped; checkbox and details use existing flows',
    (tester) async {
      await add('운영체제 과제', due: today, list: 'course', tagIds: ['tag-a']);
      await add(
        '곧 마감',
        due: today.add(const Duration(days: 2)),
        list: 'course',
      );
      await add(
        '지난 과제',
        due: today.subtract(const Duration(days: 2)),
        list: 'course',
      );
      await add('완료 과제', due: today, list: 'course', completed: true);
      await add('다른 목록 임박', due: today.add(const Duration(days: 2)));
      await pumpApp(tester);
      await chooseScope(tester, 'list', 'course');
      expect(row('곧 마감', 'urgent'), findsOneWidget);
      expect(row('지난 과제', 'overdue'), findsOneWidget);
      expect(row('완료 과제', 'completed'), findsOneWidget);
      expect(row('다른 목록 임박', 'urgent'), findsNothing);
      await capture(tester, 'home');
      await tester.tap(
        find.descendant(of: row('운영체제 과제'), matching: find.byType(Checkbox)),
      );
      await tester.pumpAndSettle();
      expect(
        (await tasks.getTaskById('운영체제 과제'))!.status,
        TaskStatus.completed,
      );
      expect(notifications.cancelled, contains('운영체제 과제'));
      await tester.ensureVisible(row('운영체제 과제', 'completed'));
      await tester.tap(
        find.descendant(
          of: row('운영체제 과제', 'completed'),
          matching: find.byType(Checkbox),
        ),
      );
      await tester.pumpAndSettle();
      expect((await tasks.getTaskById('운영체제 과제'))!.status, TaskStatus.active);
      await tester.ensureVisible(row('운영체제 과제'));
      await tester.tap(row('운영체제 과제'));
      await tester.pumpAndSettle();
      expect(find.byType(TaskDetailScreen), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await adjust(tester);
      await tester.tap(find.widgetWithText(FilterChip, '미완료'));
      await tester.pumpAndSettle();
      await dismissSheet(tester);
      expect(row('운영체제 과제'), findsNothing);
      expect(row('완료 과제', 'completed'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await finish(tester);
    },
  );

  testWidgets(
    'detail sheet edits fields with keyboard and saves through existing reminder flow',
    (tester) async {
      tester.view.physicalSize = const Size(360, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await add('상세 테스트', due: today);
      final reminders = DriftNotificationRepository(database: database);
      await reminders.save(
        const NotificationSetting(
          id: 'detail-reminder',
          taskId: '상세 테스트',
          enabled: true,
          daysBeforeDue: 60,
          notifyTime: 'relative',
        ),
      );
      await pumpApp(tester);
      await tester.tap(row('상세 테스트'));
      await tester.pumpAndSettle();
      final detail = find.byType(TaskDetailScreen);
      expect(
        find.ancestor(of: detail, matching: find.byType(BottomSheet)),
        findsOneWidget,
      );
      expect(tester.getTopLeft(detail).dy, greaterThan(0));
      expect(row('상세 테스트'), findsOneWidget);
      await capture(tester, 'detail-sheet');
      Finder field(String label) => find.descendant(
        of: detail,
        matching: find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.labelText == label,
        ),
      );
      final scrollable = find
          .descendant(of: detail, matching: find.byType(Scrollable))
          .first;
      Future<void> reveal(Finder target) async {
        await tester.scrollUntilVisible(target, 180, scrollable: scrollable);
        await tester.ensureVisible(target);
        await tester.pumpAndSettle();
      }

      await tester.enterText(field('제목'), '하단에서 수정');
      await tester.tap(find.text('마감일'));
      await tester.pumpAndSettle();
      final dateDialog = find.byType(DatePickerDialog);
      await tester.tap(
        find.descendant(
          of: dateDialog,
          matching: find.byIcon(Icons.edit_outlined),
        ),
      );
      await tester.pumpAndSettle();
      final tomorrow = DateTime(now.year, now.month, now.day + 1, 23, 59);
      await tester.enterText(
        find.descendant(of: dateDialog, matching: find.byType(TextField)),
        '${tomorrow.year}. ${tomorrow.month}. ${tomorrow.day}.',
      );
      await tester.tap(
        find.descendant(of: dateDialog, matching: find.text('확인')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(TimePickerDialog),
          matching: find.text('취소'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, '높음'));
      final course = find.widgetWithText(FilterChip, '운영체제');
      await reveal(course);
      await tester.tap(course);
      final tag = find.widgetWithText(FilterChip, '과제');
      await reveal(tag);
      await tester.tap(tag);
      await reveal(field('메모'));
      tester.view.viewInsets = const FakeViewPadding(bottom: 260);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      await reveal(field('메모'));
      await tester.enterText(field('메모'), '키보드가 열린 상태에서 저장');
      await tester.pumpAndSettle();
      expect(
        tester.getBottomLeft(field('메모')).dy,
        lessThanOrEqualTo(tester.getBottomLeft(detail).dy - 260 + 1),
      );
      expect(notifications.scheduled, isEmpty);
      await tester.tap(find.byTooltip('작업 상세 닫기'));
      await tester.pumpAndSettle();
      final saved = (await tasks.getTaskById('상세 테스트'))!;
      expect(saved.title, '하단에서 수정');
      expect(saved.dueDate, tomorrow);
      expect(saved.priority, TaskPriority.high);
      expect(saved.listId, 'course');
      expect(saved.tagIds, ['tag-a']);
      expect(saved.memo, '키보드가 열린 상태에서 저장');
      expect(saved.status, TaskStatus.active);
      expect((await reminders.getByTaskId(saved.id))!.enabled, isTrue);
      expect(notifications.scheduled.single.$1.dueDate, tomorrow);
      expect(notifications.scheduled.single.$2.enabled, isTrue);
      expect(find.byType(TaskDetailScreen), findsNothing);
      expect(tester.takeException(), isNull);
      await finish(tester);
    },
  );

  testWidgets(
    'detail sheet prevents accidental dismissal and stays open on failed atomic save',
    (tester) async {
      await add('실패 확인', due: today);
      final reminders = _FailingDetailReminders(database: database);
      await pumpApp(tester, reminders: reminders);
      await tester.tap(row('실패 확인'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '재시도 수정');
      await tester.tapAt(const Offset(10, 20));
      await tester.pumpAndSettle();
      expect(find.byType(TaskDetailScreen), findsOneWidget);
      final header = find.descendant(
        of: find.byType(TaskDetailScreen),
        matching: find.byType(AppBar),
      );
      await tester.dragFrom(tester.getCenter(header), const Offset(0, 250));
      await tester.pumpAndSettle();
      expect(find.byType(TaskDetailScreen), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(TaskDetailScreen), findsOneWidget);
      expect((await tasks.getTaskById('실패 확인'))!.title, '실패 확인');
      expect(await reminders.getByTaskId('실패 확인'), isNull);
      expect(notifications.scheduled, isEmpty);
      expect(find.textContaining('저장하지 못했습니다:'), findsWidgets);
      // The same back action retries the existing save and then closes.
      reminders.failSave = false;
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(TaskDetailScreen), findsNothing);
      expect((await tasks.getTaskById('실패 확인'))!.title, '재시도 수정');
      expect(row('실패 확인'), findsOneWidget);
      expect(notifications.scheduled, hasLength(1));
      expect(tester.takeException(), isNull);
      await finish(tester);
    },
  );

  testWidgets(
    'quick add shares create persistence and supports title only or detailed handoff',
    (tester) async {
      await pumpApp(tester);
      await tester.tap(find.byKey(const ValueKey('nav-add')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TaskCreateScreen>(find.byType(TaskCreateScreen)).quickAdd,
        isTrue,
      );
      await tester.enterText(find.byType(TextField), '제목만 추가');
      await tester.tap(find.widgetWithText(FilledButton, '추가'));
      await tester.pumpAndSettle();
      final first = (await tasks.getTasks()).single;
      expect(first.listId, inboxListId);
      expect(first.dueDate, isNull);
      expect(
        await DriftNotificationRepository(
          database: database,
        ).getByTaskId(first.id),
        isNotNull,
      );
      expect(row(first.id), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('nav-add')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '상세로 전달');
      await tester.tap(find.widgetWithText(FilterChip, '운영체제'));
      await tester.tap(find.widgetWithText(FilterChip, '과제'));
      await capture(tester, 'quick-add');
      await tester.tap(find.text('상세 설정'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TaskCreateScreen>(find.byType(TaskCreateScreen)).quickAdd,
        isFalse,
      );
      expect(find.widgetWithText(TextField, '상세로 전달'), findsOneWidget);
      await tester.tap(find.text('저장').first);
      await tester.pumpAndSettle();
      final second = (await tasks.getTasks()).singleWhere(
        (t) => t.title == '상세로 전달',
      );
      expect(second.listId, 'course');
      expect(second.tagIds, ['tag-a']);
      expect((await tasks.getTasks()).length, 2);
      expect(find.byType(TaskCreateScreen), findsNothing);
      expect(tester.takeException(), isNull);
      await finish(tester);
    },
  );

  testWidgets(
    'Drawer settings and calendar remain available at large text size',
    (tester) async {
      await pumpApp(tester, textScale: 1.5);
      await tester.tap(find.byKey(const ValueKey('nav-calendar')));
      await tester.pumpAndSettle();
      expect(find.byType(HomeCalendarSection), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('nav-home')));
      await tester.pumpAndSettle();
      await openDrawer(tester);
      await tester.tap(find.byKey(const ValueKey('drawer-settings')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('home-settings-menu')), findsOneWidget);
      expect(find.text('세션/쿠키 정리'), findsNothing);
      expect(find.text('목록·태그 관리'), findsNothing);
      await capture(tester, 'settings-large-menu');
      await tester.tap(find.text('스와이프'));
      await tester.pumpAndSettle();
      expect(find.byType(DropdownButton<TaskSwipeAction>), findsNWidgets(4));
      await capture(tester, 'swipe-large');
      expect(tester.takeException(), isNull);
      await finish(tester);
    },
  );

  testWidgets(
    'calendar uses the home task row and pins its adjustment header',
    (tester) async {
      const title = '캘린더에서도 긴 제목을 자르지 않고 여러 줄로 전부 표시하는 운영체제 과제';
      await add(
        title,
        due: DateTime(now.year, now.month, now.day, 10),
        list: 'course',
        tagIds: ['tag-a'],
        priority: TaskPriority.high,
      );
      for (var i = 0; i < 24; i++) {
        await add('캘린더 과제 $i', due: today, list: 'course');
      }
      await pumpApp(tester);
      await tester.tap(find.byKey(const ValueKey('nav-calendar')));
      await tester.pumpAndSettle();
      final row = find.byKey(const ValueKey('calendar-task-$title'));
      expect(row, findsOneWidget);
      final titleWidget = tester.widget<Text>(
        find.descendant(of: row, matching: find.text(title)),
      );
      expect(titleWidget.style!.fontSize, 13);
      expect(titleWidget.maxLines, isNull);
      expect(titleWidget.overflow, isNot(TextOverflow.ellipsis));
      expect(
        find.descendant(of: row, matching: find.text('학교 > 운영체제 · #과제')),
        findsOneWidget,
      );
      expect(tester.widget<ListTile>(row).trailing, isA<Column>());
      expect(find.byType(PopupMenuButton<String>), findsNothing);
      await capture(tester, 'calendar-month');
      await tester.tap(find.text('주'));
      await tester.pumpAndSettle();
      await capture(tester, 'calendar-week');
      final scroll = find
          .descendant(
            of: find.byKey(const ValueKey('calendar-scroll')),
            matching: find.byType(Scrollable),
          )
          .first;
      tester.state<ScrollableState>(scroll).position.jumpTo(600);
      await tester.pumpAndSettle();
      expect(
        tester
            .getTopLeft(find.byKey(const ValueKey('calendar-task-header')))
            .dy,
        0,
      );
      await capture(tester, 'calendar-pinned');
      await tester.tap(find.byTooltip('캘린더 보기 조정'));
      await tester.pumpAndSettle();
      await capture(tester, 'calendar-adjustments');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await finish(tester);
    },
  );

  testWidgets(
    'trash row checkboxes start selection without a separate selection icon',
    (tester) async {
      await trashItem('체크로 선택');
      await pumpApp(tester);
      await chooseScope(tester, 'trash');
      final checkbox = find.byKey(const ValueKey('trash-select-체크로 선택'));
      expect(
        tester.widget<ListTile>(row('체크로 선택', 'trash')).leading,
        isA<Checkbox>(),
      );
      expect(find.byIcon(Icons.checklist_rounded), findsNothing);
      expect(find.byKey(const ValueKey('trash-selection-mode')), findsNothing);
      await tester.tap(checkbox);
      await tester.pumpAndSettle();
      expect(tester.widget<Checkbox>(checkbox).value, isTrue);
      expect(selectionCount(1), findsOneWidget);
      expect(find.byType(TaskDetailScreen), findsNothing);
      expect((await tasks.getTaskById('체크로 선택'))!.status, TaskStatus.deleted);
      await tester.tap(find.byKey(const ValueKey('selection-back')));
      await tester.pumpAndSettle();
      expect(tester.widget<Checkbox>(checkbox).value, isFalse);
      expect(
        find.byKey(const ValueKey('trash-restore-selected')),
        findsNothing,
      );
      await capture(tester, 'trash-checkboxes');
      expect(tester.takeException(), isNull);
      await finish(tester);
    },
  );

  for (final excluded in [false, true]) {
    for (final textScale in [1.0, 1.5]) {
      testWidgets(
        'archive checkbox header stays fixed and row taps only select: excluded=$excluded textScale=$textScale',
        (tester) async {
          final section = excluded ? 'excluded' : 'trash';
          final captureSection = textScale == 1 ? section : '$section-large';
          for (var i = 0; i < 12; i++) {
            if (excluded) {
              await tasks.createTask(
                Task(
                  id: 'archive-$i',
                  title: '보관 항목 $i',
                  origin: TaskOrigin.ecampus,
                  status: TaskStatus.excluded,
                  createdAt: now,
                  updatedAt: now,
                  ecampus: EcampusSyncMetadata(
                    sourceKey: 'archive-$i',
                    sourceCourse: '운영체제',
                  ),
                ),
              );
            } else {
              await trashItem('archive-$i');
            }
          }
          await pumpApp(tester, textScale: textScale);
          if (excluded) {
            await openDrawer(tester);
            await tester.ensureVisible(
              find.byKey(const ValueKey('drawer-excluded')),
            );
            await tester.tap(find.byKey(const ValueKey('drawer-excluded')));
            await tester.pumpAndSettle();
          } else {
            await chooseScope(tester, 'trash');
          }
          final checkbox = find.byKey(ValueKey('$section-select-archive-0'));
          expect(
            tester.widget<ListTile>(row('archive-0', section)).leading,
            isA<Checkbox>(),
          );
          expect(find.byKey(const ValueKey('selection-toolbar')), findsNothing);
          final normalRowTop = tester.getTopLeft(row('archive-0', section)).dy;
          await tester.tap(row('archive-0', section));
          await tester.pumpAndSettle();
          expect(selectionCount(1), findsOneWidget);
          expect(
            tester.getTopLeft(row('archive-0', section)).dy,
            lessThanOrEqualTo(normalRowTop + 8),
          );
          expect(tester.widget<Checkbox>(checkbox).value, isTrue);
          expect(find.byType(TaskDetailScreen), findsNothing);
          expect(find.byTooltip('휴지통 작업 메뉴'), findsNothing);
          expect(find.text('선택 취소'), findsNothing);
          expect(find.text('전체 선택'), findsNothing);
          expect(find.text('1개 선택'), findsNothing);
          expect(find.byTooltip('보기 조정'), findsNothing);
          final action = find.byKey(
            ValueKey(
              excluded ? 'excluded-restore-selected' : 'trash-restore-selected',
            ),
          );
          expect(tester.widget<IconButton>(action).tooltip, '복원');
          if (excluded) {
            expect(
              find.byKey(const ValueKey('trash-delete-selected')),
              findsNothing,
            );
            expect(find.byIcon(Icons.check_rounded), findsOneWidget);
            expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
          } else {
            expect(
              find.byKey(const ValueKey('trash-delete-selected')),
              findsOneWidget,
            );
          }
          await tester.tap(checkbox);
          await tester.pumpAndSettle();
          expect(selectionCount(0), findsOneWidget);
          expect(tester.widget<IconButton>(action).onPressed, isNull);
          final selectAll = find.byKey(ValueKey('$section-select-all'));
          expect(
            tester
                .widget<AppBar>(find.byKey(const ValueKey('selection-toolbar')))
                .centerTitle,
            isFalse,
          );
          expect(
            tester
                .getCenter(
                  find.descendant(
                    of: selectAll,
                    matching: find.byType(Checkbox),
                  ),
                )
                .dx,
            tester.getCenter(checkbox).dx,
          );
          expect(tester.getSize(selectAll).height, 48);
          expect(
            tester
                .widget<AppBar>(find.byKey(const ValueKey('selection-toolbar')))
                .preferredSize
                .height,
            104,
          );
          await tester.tap(selectAll);
          await tester.pumpAndSettle();
          expect(selectionCount(12), findsOneWidget);
          expect(find.text('모두 해제'), findsOneWidget);
          await capture(tester, '$captureSection-selection-all');
          await tester.tap(selectAll);
          await tester.pumpAndSettle();
          expect(selectionCount(0), findsOneWidget);
          expect(find.text('모두 선택'), findsOneWidget);
          await tester.tap(row('archive-0', section));
          await tester.pumpAndSettle();
          final toolbar = find.byKey(const ValueKey('selection-toolbar'));
          final before = tester.getRect(toolbar);
          final allBefore = tester.getRect(selectAll);
          await capture(tester, '$captureSection-selection-header');
          await tester.dragFrom(const Offset(180, 450), const Offset(0, -450));
          await tester.pumpAndSettle();
          expect(tester.getRect(toolbar), before);
          expect(tester.getRect(selectAll), allBefore);
          expect(selectionCount(1), findsOneWidget);
          await capture(tester, '$captureSection-selection-scrolled');
          await tester.tap(find.byKey(const ValueKey('selection-back')));
          await tester.pumpAndSettle();
          expect(toolbar, findsNothing);
          expect(tester.widget<Checkbox>(checkbox).value, isFalse);
          final scrollable = find
              .ancestor(
                of: row('archive-0', section),
                matching: find.byType(Scrollable),
              )
              .first;
          tester.state<ScrollableState>(scrollable).position.jumpTo(0);
          await tester.pumpAndSettle();
          expect(row('archive-0', section).hitTestable(), findsOneWidget);
          await tester.tap(row('archive-0', section));
          await tester.pumpAndSettle();
          expect(selectionCount(1), findsOneWidget);
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(toolbar, findsNothing);
          expect(tester.widget<Checkbox>(checkbox).value, isFalse);
          expect(
            (await tasks.getTasks(
              status: excluded ? TaskStatus.excluded : TaskStatus.deleted,
            )).length,
            12,
          );
          expect(tester.takeException(), isNull);
          await finish(tester);
        },
      );
    }
  }

  testWidgets(
    'excluded checkbox bulk restore preserves unselected sources and retries failures',
    (tester) async {
      final failing = _FailingExcludedTasks(database: database)
        ..failId = 'source-b';
      tasks = failing;
      for (final id in ['source-a', 'source-b', 'source-c']) {
        await tasks.createTask(
          Task(
            id: id,
            title: id,
            origin: TaskOrigin.ecampus,
            status: TaskStatus.excluded,
            createdAt: now,
            updatedAt: now,
            ecampus: EcampusSyncMetadata(sourceKey: id),
          ),
        );
      }
      await pumpApp(tester);
      await openDrawer(tester);
      await tester.ensureVisible(find.byKey(const ValueKey('drawer-excluded')));
      await tester.tap(find.byKey(const ValueKey('drawer-excluded')));
      await tester.pumpAndSettle();
      await tester.tap(row('source-a', 'excluded'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('excluded-select-source-b')));
      await tester.pumpAndSettle();
      expect(selectionCount(2), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('excluded-restore-selected')));
      await tester.pumpAndSettle();
      expect(selectionCount(1), findsOneWidget);
      expect(row('source-a', 'excluded'), findsNothing);
      expect(
        tester
            .widget<Checkbox>(
              find.byKey(const ValueKey('excluded-select-source-b')),
            )
            .value,
        isTrue,
      );
      expect(
        tester
            .widget<Checkbox>(
              find.byKey(const ValueKey('excluded-select-source-c')),
            )
            .value,
        isFalse,
      );
      final sources = {
        for (final source in await database.select(database.ecampusItems).get())
          source.id: source,
      };
      expect(sources['source-a']!.importState, 'unreviewed');
      expect(sources['source-b']!.importState, 'ignored');
      expect(sources['source-c']!.importState, 'ignored');
      expect(await database.select(database.tasks).get(), isEmpty);
      failing.failDelete = false;
      await tester.tap(find.byKey(const ValueKey('excluded-restore-selected')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('selection-toolbar')), findsNothing);
      expect(row('source-c', 'excluded'), findsOneWidget);
      expect(
        (await tasks.getTasks(status: TaskStatus.excluded)).single.id,
        'source-c',
      );
      expect(await database.select(database.tasks).get(), isEmpty);
      expect(tester.takeException(), isNull);
      await finish(tester);
    },
  );

  testWidgets(
    'trash filter choices use only deleted tasks and filter retained completion state',
    (tester) async {
      tester.view.physicalSize = const Size(360, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await trashItem(
        '완료 원본',
        completed: true,
        priority: TaskPriority.high,
        tagIds: ['tag-a'],
      );
      await trashItem('미완료 원본');
      await add(
        '휴지통 밖',
        due: today,
        priority: TaskPriority.medium,
        tagIds: ['tag-b'],
      );
      await pumpApp(tester);
      await chooseScope(tester, 'trash');
      Finder chip(String label) => find.descendant(
        of: find.byType(BottomSheet),
        matching: find.widgetWithText(FilterChip, label),
      );
      Future<void> tapChip(String label) async {
        await tester.ensureVisible(chip(label));
        await tester.pumpAndSettle();
        await tester.tap(chip(label));
        await tester.pumpAndSettle();
      }

      await adjust(tester);
      expect(chip('미완료'), findsOneWidget);
      expect(chip('완료'), findsOneWidget);
      expect(chip('높음'), findsOneWidget);
      expect(chip('중간'), findsNothing);
      expect(chip('낮음'), findsNothing);
      expect(chip('#과제'), findsOneWidget);
      expect(chip('#개인'), findsNothing);
      await tapChip('미완료');
      await tapChip('높음');
      await tapChip('#과제');
      await capture(tester, 'trash-filter-options');
      await tester.tap(find.widgetWithText(TextButton, '닫기'));
      await tester.pumpAndSettle();
      expect(row('완료 원본', 'trash'), findsOneWidget);
      expect(row('미완료 원본', 'trash'), findsNothing);
      await adjust(tester);
      // Choices stay based on all trash, not on the filtered result.
      expect(chip('미완료'), findsOneWidget);
      expect(chip('완료'), findsOneWidget);
      await tapChip('완료');
      await tester.tap(find.widgetWithText(TextButton, '닫기'));
      await tester.pumpAndSettle();
      expect(row('완료 원본', 'trash'), findsNothing);
      expect(row('미완료 원본', 'trash'), findsNothing);
      expect((await settings.getSettings()).homeView.isDefault, isTrue);
      await tasks.deletePermanently('완료 원본');
      await restart(tester);
      await chooseScope(tester, 'trash');
      await adjust(tester);
      expect(chip('미완료'), findsOneWidget);
      expect(chip('완료'), findsNothing);
      expect(chip('높음'), findsNothing);
      expect(chip('중간'), findsNothing);
      expect(chip('낮음'), findsNothing);
      expect(chip('#과제'), findsNothing);
      expect(chip('#개인'), findsNothing);
      expect(find.text('우선순위가 지정된 항목이 없습니다.'), findsOneWidget);
      expect(find.text('휴지통에 사용한 태그가 없습니다.'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, '닫기'));
      await tester.pumpAndSettle();
      await tasks.deletePermanently('미완료 원본');
      await restart(tester);
      await chooseScope(tester, 'trash');
      await adjust(tester);
      expect(chip('미완료'), findsNothing);
      expect(chip('완료'), findsNothing);
      expect(find.text('휴지통에 항목이 없습니다.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await finish(tester);
    },
  );

  testWidgets(
    'trash selection restores only selected tasks and keeps completion and list metadata',
    (tester) async {
      tester.view.physicalSize = const Size(360, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await trashItem('선택 A');
      await trashItem('선택 B', completed: true);
      await trashItem('남길 C');
      await add('일반 D', due: today);
      await pumpApp(tester, textScale: 1.5);
      await chooseScope(tester, 'trash');
      await startTrashSelection(tester);
      expect(
        tester
            .widget<IconButton>(
              find.byKey(const ValueKey('trash-restore-selected')),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.byKey(const ValueKey('trash-select-all')));
      await tester.pumpAndSettle();
      expect(selectionCount(3), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('trash-select-all')));
      await tester.pumpAndSettle();
      expect(selectionCount(0), findsOneWidget);
      await tester.tap(row('선택 A', 'trash'));
      await tester.pumpAndSettle();
      expect(find.byType(TaskDetailScreen), findsNothing);
      await swipeTask(tester, '선택 A', toRight: true, section: 'trash');
      expect((await tasks.getTaskById('선택 A'))!.status, TaskStatus.deleted);
      expect(find.byKey(const ValueKey('drawer-settings')), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Checkbox>(find.byKey(const ValueKey('trash-select-선택 A')))
            .value,
        isFalse,
      );
      expect(
        find.byKey(const ValueKey('trash-restore-selected')),
        findsNothing,
      );
      await startTrashSelection(tester);
      await tester.tap(row('선택 A', 'trash'));
      await tester.tap(row('선택 B', 'trash'));
      await tester.pumpAndSettle();
      await capture(tester, 'trash-selection');
      await tester.tap(find.byKey(const ValueKey('trash-restore-selected')));
      await tester.pumpAndSettle();
      final a = (await tasks.getTaskById('선택 A'))!;
      final b = (await tasks.getTaskById('선택 B'))!;
      expect(a.status, TaskStatus.active);
      expect(b.status, TaskStatus.completed);
      expect(a.listId, 'course');
      expect(b.listId, 'course');
      expect((await tasks.getTaskById('남길 C'))!.status, TaskStatus.deleted);
      expect((await tasks.getTaskById('일반 D'))!.status, TaskStatus.active);
      expect(
        find.byKey(const ValueKey('trash-restore-selected')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
      await finish(tester);
    },
  );

  testWidgets(
    'trash selected delete confirms once, cancels safely and deletes only checked rows',
    (tester) async {
      for (final id in ['선택 A', '선택 B', '남길 C']) {
        await trashItem(id);
      }
      await pumpApp(tester);
      await chooseScope(tester, 'trash');
      await startTrashSelection(tester);
      await tester.tap(row('선택 A', 'trash'));
      await tester.tap(row('선택 B', 'trash'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('trash-delete-selected')));
      await tester.pumpAndSettle();
      expect(find.text('2개를 영구 삭제할까요?'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, '취소'));
      await tester.pumpAndSettle();
      expect((await tasks.getTasks(status: TaskStatus.deleted)).length, 3);
      expect(selectionCount(2), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('trash-delete-selected')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(FilledButton, '삭제'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(await tasks.getTaskById('선택 A'), isNull);
      expect(await tasks.getTaskById('선택 B'), isNull);
      expect((await tasks.getTaskById('남길 C'))!.status, TaskStatus.deleted);
      expect(tester.takeException(), isNull);
      await finish(tester);
    },
  );

  testWidgets(
    'trash view is temporary and independent of saved home sorting and filters',
    (tester) async {
      const homeView = HomeViewOptions(
        sort: HomeSort.dueLate,
        tagIds: {'tag-a'},
      );
      await settings.saveSettings(
        (await settings.getSettings()).copyWith(homeView: homeView),
      );
      final early = DateTime(now.year, now.month, now.day, 10);
      final late = DateTime(now.year, now.month, now.day, 23, 59);
      await trashItem('A 이른 마감', due: early, tagIds: ['tag-a']);
      await trashItem('B 늦은 마감', due: late, tagIds: ['tag-b']);
      await add('홈 이른 마감', due: early, tagIds: ['tag-a']);
      await add('홈 늦은 마감', due: late, tagIds: ['tag-a']);
      await pumpApp(tester);
      await chooseScope(tester, 'trash');
      expect(row('B 늦은 마감', 'trash'), findsOneWidget);
      expect(
        tester.getTopLeft(row('A 이른 마감', 'trash')).dy,
        lessThan(tester.getTopLeft(row('B 늦은 마감', 'trash')).dy),
      );
      Future<void> setTemporarySort() async {
        await adjust(tester);
        expect(find.text('휴지통 보기 (임시)'), findsOneWidget);
        expect(find.widgetWithText(FilledButton, '저장'), findsNothing);
        await tester.tap(find.text('마감 늦은 순'));
        await capture(tester, 'trash-view');
        await tester.tap(find.widgetWithText(TextButton, '닫기'));
        await tester.pumpAndSettle();
      }

      await setTemporarySort();
      expect(
        tester.getTopLeft(row('B 늦은 마감', 'trash')).dy,
        lessThan(tester.getTopLeft(row('A 이른 마감', 'trash')).dy),
      );
      expect(
        (await settings.getSettings()).homeView.encode(),
        homeView.encode(),
      );
      await chooseScope(tester, 'period');
      expect(
        tester.getTopLeft(row('홈 늦은 마감')).dy,
        lessThan(tester.getTopLeft(row('홈 이른 마감')).dy),
      );
      await chooseScope(tester, 'trash');
      expect(
        tester.getTopLeft(row('A 이른 마감', 'trash')).dy,
        lessThan(tester.getTopLeft(row('B 늦은 마감', 'trash')).dy),
      );
      await setTemporarySort();
      await tester.tap(find.byKey(const ValueKey('nav-calendar')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('nav-home')));
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(row('A 이른 마감', 'trash')).dy,
        lessThan(tester.getTopLeft(row('B 늦은 마감', 'trash')).dy),
      );
      await restart(tester);
      await chooseScope(tester, 'trash');
      expect(
        tester.getTopLeft(row('A 이른 마감', 'trash')).dy,
        lessThan(tester.getTopLeft(row('B 늦은 마감', 'trash')).dy),
      );
      expect(
        (await settings.getSettings()).homeView.encode(),
        homeView.encode(),
      );
      expect(tester.takeException(), isNull);
      await finish(tester);
    },
  );

  testWidgets(
    'trash select all only targets visible rows and clears selection when filters or dates change',
    (tester) async {
      await trashItem('보이는 A', tagIds: ['tag-a']);
      await trashItem('숨길 B', tagIds: ['tag-b']);
      await pumpApp(tester);
      await chooseScope(tester, 'trash');
      await startTrashSelection(tester);
      await tester.tap(row('숨길 B', 'trash'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('selection-back')));
      await tester.pumpAndSettle();
      await adjust(tester);
      final chip = find.widgetWithText(FilterChip, '#과제');
      await tester.ensureVisible(chip);
      await tester.tap(chip);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, '닫기'));
      await tester.pumpAndSettle();
      await startTrashSelection(tester);
      expect(selectionCount(0), findsOneWidget);
      expect(row('숨길 B', 'trash'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('trash-select-all')));
      await tester.pumpAndSettle();
      expect(selectionCount(1), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await choosePeriod(tester, '이번 주');
      await startTrashSelection(tester);
      expect(selectionCount(0), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('trash-select-all')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('trash-restore-selected')));
      await tester.pumpAndSettle();
      expect((await tasks.getTaskById('보이는 A'))!.status, TaskStatus.active);
      expect((await tasks.getTaskById('숨길 B'))!.status, TaskStatus.deleted);
      expect(tester.takeException(), isNull);
      await finish(tester);
    },
  );

  for (final restore in [true, false]) {
    testWidgets(
      'trash bulk failure retains only failed selection and supports retry: restore=$restore',
      (tester) async {
        final failing = _FailingBulkTrashTasks(database: database);
        tasks = failing;
        for (final id in ['선택 A', '선택 B', '남길 C']) {
          await trashItem(id);
        }
        await pumpApp(tester);
        await chooseScope(tester, 'trash');
        await startTrashSelection(tester);
        await tester.tap(row('선택 A', 'trash'));
        await tester.tap(row('선택 B', 'trash'));
        await tester.pumpAndSettle();
        Future<void> apply() async {
          await tester.tap(
            find.byKey(
              ValueKey(
                restore ? 'trash-restore-selected' : 'trash-delete-selected',
              ),
            ),
          );
          await tester.pumpAndSettle();
          if (!restore) {
            await tester.tap(
              find.descendant(
                of: find.byType(AlertDialog),
                matching: find.widgetWithText(FilledButton, '삭제'),
              ),
            );
            await tester.pumpAndSettle();
          }
        }

        await apply();
        expect(
          (await tasks.getTaskById('선택 A'))?.status,
          restore ? TaskStatus.active : isNull,
        );
        expect((await tasks.getTaskById('선택 B'))!.status, TaskStatus.deleted);
        expect(
          tester
              .widget<Checkbox>(find.byKey(const ValueKey('trash-select-선택 B')))
              .value,
          isTrue,
        );
        expect(
          tester
              .widget<Checkbox>(find.byKey(const ValueKey('trash-select-남길 C')))
              .value,
          isFalse,
        );
        expect(selectionCount(1), findsOneWidget);
        expect(find.textContaining('1개 처리, 1개 오류'), findsWidgets);
        failing.failB = false;
        await apply();
        expect(
          (await tasks.getTaskById('선택 B'))?.status,
          restore ? TaskStatus.active : isNull,
        );
        expect((await tasks.getTaskById('남길 C'))!.status, TaskStatus.deleted);
        expect(tester.takeException(), isNull);
        await finish(tester);
      },
    );
  }

  testWidgets(
    'completed and trash scopes use existing completion and restore policies',
    (tester) async {
      await add('완료 항목', due: today, list: 'course', completed: true);
      await add('삭제 항목', due: today, list: 'course');
      await tasks.markDeleted('삭제 항목');
      await pumpApp(tester);
      await chooseScope(tester, 'completed');
      expect(row('완료 항목', 'completed'), findsOneWidget);
      expect(find.byKey(const ValueKey('home-section-period')), findsNothing);
      await tester.tap(
        find.descendant(
          of: row('완료 항목', 'completed'),
          matching: find.byType(Checkbox),
        ),
      );
      await tester.pumpAndSettle();
      expect((await tasks.getTaskById('완료 항목'))!.status, TaskStatus.active);
      await chooseScope(tester, 'trash');
      expect(row('삭제 항목', 'trash'), findsOneWidget);
      await tester.tap(row('삭제 항목', 'trash'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('trash-restore-selected')));
      await tester.pumpAndSettle();
      expect((await tasks.getTaskById('삭제 항목'))!.listId, 'course');
      expect((await tasks.getTaskById('삭제 항목'))!.status, TaskStatus.active);
      expect(row('삭제 항목', 'trash'), findsNothing);
      expect(tester.takeException(), isNull);
      await finish(tester);
    },
  );

  testWidgets(
    'import button opens eCampus import without the old step dashboard',
    (tester) async {
      await pumpApp(tester);
      await tester.tap(find.byTooltip('eCampus 가져오기'));
      await tester.pump();
      expect(
        find.byType(EcampusSyncProgressScreen, skipOffstage: false),
        findsOneWidget,
      );
      expect(find.text('동기화 상태'), findsNothing);
      expect(find.text('e-campus 동기화'), findsNothing);
      await finish(tester);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}

class _Notifications extends LocalNotificationService {
  int permissionRequests = 0;
  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return true;
  }

  final cancelled = <String>[];
  final scheduled = <(Task, NotificationSetting)>[];
  @override
  Future<void> scheduleTaskNotification({
    required Task task,
    required NotificationSetting setting,
    bool requestPermissionBeforeScheduling = false,
  }) async {
    scheduled.add((task, setting));
  }

  @override
  Future<void> cancelTaskNotification(String taskId) async {
    cancelled.add(taskId);
  }
}

class _FailingDetailReminders extends DriftNotificationRepository {
  _FailingDetailReminders({required super.database});
  bool failSave = true;

  @override
  Future<NotificationSetting> save(NotificationSetting setting) {
    if (failSave) throw StateError('test reminder save failure');
    return super.save(setting);
  }
}

class _FailingSwipeTasks extends DriftTaskRepository {
  _FailingSwipeTasks({required super.database});
  bool failDelete = true;
  @override
  Future<Task> markDeleted(String id) {
    if (failDelete) throw StateError('test swipe failure');
    return super.markDeleted(id);
  }
}

class _FailingExcludedTasks extends DriftTaskRepository {
  _FailingExcludedTasks({required super.database});
  bool failDelete = true;
  String? failId;
  @override
  Future<void> deletePermanently(String id) {
    if (failDelete && (failId == null || id == failId)) {
      throw StateError('test excluded allow failure');
    }
    return super.deletePermanently(id);
  }
}

class _FailingSwipeSettings extends DriftSettingsRepository {
  _FailingSwipeSettings({required super.database});
  bool failSave = true;
  @override
  Future<AppSettings> saveSettings(AppSettings settings) {
    if (failSave) throw StateError('test settings save failure');
    return super.saveSettings(settings);
  }
}

class _FailingBulkTrashTasks extends DriftTaskRepository {
  _FailingBulkTrashTasks({required super.database});
  bool failB = true;
  @override
  Future<Task> restoreTask(String id) {
    if (failB && id == '선택 B') throw StateError('test restore failure');
    return super.restoreTask(id);
  }

  @override
  Future<void> deletePermanently(String id) {
    if (failB && id == '선택 B') throw StateError('test delete failure');
    return super.deletePermanently(id);
  }
}

class _Widgets extends WidgetUpdateService {
  _Widgets({
    required DriftTaskRepository tasks,
    required DriftSettingsRepository settings,
    required DriftFolderRepository lists,
  }) : super(
         taskRepository: tasks,
         settingsRepository: settings,
         folderRepository: lists,
       );
  @override
  Future<void> refresh() async {}
  @override
  Future<void> applyPendingWidgetCompletions() async {}
}
