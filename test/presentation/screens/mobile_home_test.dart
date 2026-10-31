import 'dart:io';
import 'dart:ui' as ui;
import 'package:drift/native.dart';
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
import 'package:ku_task_management/data/models/task_models.dart';
import 'package:ku_task_management/data/repositories/drift_folder_repository.dart';
import 'package:ku_task_management/data/repositories/drift_notification_repository.dart';
import 'package:ku_task_management/data/repositories/drift_settings_repository.dart';
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
              tags: tags,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> finish(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox.shrink());
  Future<void> restart(WidgetTester tester) async {
    await finish(tester);
    await pumpApp(tester);
  }

  Finder row(String id, [String section = 'period']) =>
      find.byKey(ValueKey('home-task-$section-$id'));
  Future<void> openDrawer(WidgetTester tester) async {
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

  testWidgets(
    'home defaults to today with four plain sections and empty states',
    (tester) async {
      await pumpApp(tester);
      for (final section in ['period', 'urgent', 'overdue', 'completed']) {
        expect(find.byKey(ValueKey('home-section-$section')), findsOneWidget);
      }
      expect(find.textContaining('오늘 ·'), findsOneWidget);
      expect(find.text('표시할 할 일이 없습니다.'), findsNWidgets(4));
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
    'home left edge swipe opens Drawer and closing keeps the current scope',
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
      await tester.flingFrom(tester.getCenter(row('미지정 일정')), const Offset(150, 0), 1000);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ListTile>(
              find.byKey(const ValueKey('scope-list-kutodo:inbox')),
            )
            .selected,
        isTrue,
      );
      await capture(tester, 'drawer-swipe');
      await tester.dragFrom(const Offset(280, 300), const Offset(-270, 0));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('drawer-settings')), findsNothing);
      expect(row('미지정 일정'), findsOneWidget);
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
      expect(find.text('세션/쿠키 정리'), findsOneWidget);
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
            .widget<ListTile>(find.byKey(const ValueKey('scope-all-')))
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
            .widget<ListTile>(find.byKey(const ValueKey('scope-all-')))
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
      await chooseScope(tester, 'all');
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
        for (final label in ['숨김 관리', '폴더 추가', '목록 추가'])
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
    'visibility manager persists individual choices, protects Inbox and preserves tasks and other settings',
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
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('drawer-folder-school')),
          matching: find.text('학교'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('scope-list-course')), findsNothing);
      expect(find.byKey(const ValueKey('scope-tag-tag-a')), findsNothing);
      expect(
        find.byKey(const ValueKey('scope-list-kutodo:inbox')),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('숨김 관리'));
      await tester.pumpAndSettle();
      final listSwitch = find.byKey(const ValueKey('visibility-list-course'));
      final tagSwitch = find.byKey(const ValueKey('visibility-tag-tag-a'));
      final inboxSwitch = tester.widget<SwitchListTile>(
        find.byKey(const ValueKey('visibility-list-kutodo:inbox')),
      );
      expect(inboxSwitch.value, isFalse);
      expect(inboxSwitch.onChanged, isNull);
      expect(tester.widget<SwitchListTile>(listSwitch).value, isTrue);
      await tester.tap(listSwitch);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        tagSwitch,
        100,
        scrollable: find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.ensureVisible(tagSwitch);
      await tester.tap(tagSwitch);
      await tester.pumpAndSettle();
      await capture(tester, 'visibility');
      await tester.tap(find.widgetWithText(TextButton, '닫기'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('scope-list-course')), findsOneWidget);
      expect(find.byKey(const ValueKey('scope-tag-tag-a')), findsOneWidget);
      expect(
        tester
            .widget<ListTile>(find.byKey(const ValueKey('scope-all-')))
            .selected,
        isTrue,
      );
      expect(row('숨긴 목록의 과제'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('scope-list-course')));
      await tester.pumpAndSettle();
      await openDrawer(tester);
      await tester.tap(find.byTooltip('숨김 관리'));
      await tester.pumpAndSettle();
      await tester.tap(listSwitch);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        tagSwitch,
        100,
        scrollable: find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.ensureVisible(tagSwitch);
      await tester.tap(tagSwitch);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, '닫기'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('scope-list-course')), findsNothing);
      expect(find.byKey(const ValueKey('scope-tag-tag-a')), findsNothing);
      // Hiding only changes navigation visibility, including a selected list.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(row('숨긴 목록의 과제'), findsOneWidget);
      expect((await settings.getSettings()).hiddenFolderIds, {
        'course',
        inboxListId,
      });
      expect((await settings.getSettings()).hiddenTagIds, {'tag-a'});
      expect((await settings.getSettings()).urgentDueDays, 7);
      expect((await settings.getSettings()).homeView.sort, HomeSort.dueLate);
      expect((await tasks.getTasks()).single.listId, 'course');
      await restart(tester);
      await openDrawer(tester);
      expect(find.byKey(const ValueKey('scope-tag-tag-a')), findsNothing);
      await tester.tap(find.byTooltip('숨김 관리'));
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(listSwitch).value, isTrue);
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
            .widget<ListTile>(find.byKey(const ValueKey('scope-all-')))
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
      await choosePeriod(tester, '전체');
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
      await tester.tap(find.byKey(const ValueKey('scope-all-')));
      await tester.pumpAndSettle();
      await capture(tester, 'all-dates');
      await choosePeriod(tester, '오늘');
      expect(row('먼 마감 일정'), findsNothing);
      for (final label in ['오늘', '이번 주', '이번 달']) {
        await choosePeriod(tester, label);
        await openDrawer(tester);
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('scope-all-')),
            matching: find.text(label),
          ),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const ValueKey('scope-all-')));
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
        expect(options, ['오늘', '이번 주', '이번 달', '전체', '기간 선택']);
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

  testWidgets('month and single custom date are session state only', (
    tester,
  ) async {
    await add('선택 날짜 일정', due: DateTime(2030, 11, 12, 23, 59));
    await pumpApp(tester);
    await choosePeriod(tester, '이번 달');
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
    expect(find.textContaining('오늘 ·'), findsOneWidget);
    expect(row('선택 날짜 일정'), findsNothing);
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
      expect(find.textContaining('오늘 ·'), findsOneWidget);
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
      expect(find.text('세션/쿠키 정리'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('목록·태그 관리'), 250);
      await tester.ensureVisible(find.text('목록·태그 관리'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('목록·태그 관리'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('상위 폴더 추가'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await finish(tester);
    },
  );

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
      await tester.tap(find.byTooltip('휴지통 작업 메뉴'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('복원'));
      await tester.pumpAndSettle();
      expect((await tasks.getTaskById('삭제 항목'))!.listId, 'course');
      expect((await tasks.getTaskById('삭제 항목'))!.status, TaskStatus.active);
      expect(row('삭제 항목', 'trash'), findsNothing);
      expect(tester.takeException(), isNull);
      await finish(tester);
    },
  );

  testWidgets('import button opens the existing eCampus progress route', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.byTooltip('eCampus 가져오기'));
    await tester.pump();
    expect(
      find.byType(EcampusSyncProgressScreen, skipOffstage: false),
      findsOneWidget,
    );
    await finish(tester);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

class _Notifications extends LocalNotificationService {
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
