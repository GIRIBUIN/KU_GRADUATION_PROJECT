import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:ku_task_management/core/theme/app_theme.dart';
import 'package:ku_task_management/data/models/task_models.dart';
import 'package:ku_task_management/presentation/widgets/home_calendar_section.dart';

void main() {
  setUpAll(() => initializeDateFormatting('ko_KR'));
  late List<Task> tasks;
  DateTime? createdDay;
  Task? openedTask;
  Task? toggledTask;
  Task? deletedTask;

  setUp(() {
    tasks = [
      task('personal', 15),
      task('school', 15, origin: TaskOrigin.ecampus),
      task('done', 15, status: TaskStatus.completed),
      task('next', 16),
      task('undated', null),
    ];
    createdDay = null;
    openedTask = null;
    toggledTask = null;
    deletedTask = null;
  });

  Future<void> pumpCalendar(
    WidgetTester tester, {
    bool isLoading = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko', 'KR'),
        supportedLocales: const [Locale('ko', 'KR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(
          body: HomeCalendarSection(
            initialDay: DateTime(2026, 6, 15),
            tasks: tasks,
            isLoading: isLoading,
            onCreateTask: (day) => createdDay = day,
            onOpenTask: (task) => openedTask = task,
            onToggleTask: (task) => toggledTask = task,
            onDeleteTask: (task) => deletedTask = task,
          ),
        ),
      ),
    );
    if (isLoading) {
      await tester.pump();
    } else {
      await tester.pumpAndSettle();
    }
  }

  testWidgets(
    'selects a date, adds on that date, opens and completes existing tasks',
    (tester) async {
      tester.view.physicalSize = const Size(600, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await pumpCalendar(tester);
      expect(find.text('할 일'), findsOneWidget);
      expect(
        tester
            .widgetList<Text>(
              find.descendant(
                of: find.byKey(const ValueKey('calendar-task-header')),
                matching: find.byType(Text),
              ),
            )
            .map((text) => text.data),
        ['할 일'],
      );
      await tester.tap(find.byKey(const ValueKey('calendar-task-school')));
      expect(openedTask?.id, 'school');
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('calendar-task-personal')),
          matching: find.byType(Checkbox),
        ),
      );
      expect(toggledTask?.id, 'personal');
      await tester.tap(find.text('16').hitTestable().first);
      await tester.pumpAndSettle();
      expect(
        tester
            .widgetList<Text>(
              find.descendant(
                of: find.byKey(const ValueKey('calendar-task-header')),
                matching: find.byType(Text),
              ),
            )
            .map((text) => text.data),
        ['할 일'],
      );
      expect(
        find.byKey(const ValueKey('calendar-task-personal')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('calendar-task-next')), findsOneWidget);
      await tester.tap(find.byTooltip('선택한 날짜에 일정 추가'));
      expect(createdDay, DateTime(2026, 6, 16));
      await tester.longPress(find.byKey(const ValueKey('calendar-task-next')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();
      expect(deletedTask?.id, 'next');
    },
  );

  testWidgets(
    'navigates months and weeks, jumps to today, and reflects refreshed tasks',
    (tester) async {
      await pumpCalendar(tester);
      await tester.tap(find.byTooltip('다음 기간'));
      await tester.pumpAndSettle();
      expect(find.text('2026년 7월'), findsOneWidget);
      await tester.tap(find.byTooltip('이전 기간'));
      await tester.pumpAndSettle();
      expect(find.text('2026년 6월'), findsOneWidget);
      await tester.tap(find.text('주'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TableCalendar<Task>>(find.byType(TableCalendar<Task>))
            .calendarFormat,
        CalendarFormat.week,
      );
      final beforeWeek = tester
          .widget<TableCalendar<Task>>(find.byType(TableCalendar<Task>))
          .focusedDay;
      await tester.tap(find.byTooltip('다음 기간'));
      await tester.pumpAndSettle();
      final afterWeek = tester
          .widget<TableCalendar<Task>>(find.byType(TableCalendar<Task>))
          .focusedDay;
      expect(afterWeek.difference(beforeWeek).inDays, 7);
      expect(find.textContaining('~'), findsOneWidget);
      tasks = [task('refreshed', 15)];
      await pumpCalendar(tester);
      expect(
        tester
            .widgetList<Text>(
              find.descendant(
                of: find.byKey(const ValueKey('calendar-task-header')),
                matching: find.byType(Text),
              ),
            )
            .map((text) => text.data),
        ['할 일'],
      );
      expect(
        find.byKey(const ValueKey('calendar-task-refreshed')),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('오늘로 이동'));
      await tester.pumpAndSettle();
      final now = DateTime.now();
      final calendar = tester.widget<TableCalendar<Task>>(
        find.byType(TableCalendar<Task>),
      );
      expect(isSameDay(calendar.focusedDay, now), true);
      expect(calendar.selectedDayPredicate!(now), true);
    },
  );

  testWidgets(
    'filters completed and source types and makes undated tasks accessible',
    (tester) async {
      tester.view.physicalSize = const Size(600, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await pumpCalendar(tester);
      await tester.tap(find.byTooltip('캘린더 보기 조정'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('calendar-task-done')), findsNothing);
      await tester.tap(find.widgetWithText(ChoiceChip, 'e-campus 일정'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('calendar-task-personal')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('calendar-task-school')),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(ChoiceChip, '전체 일정'));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.text('날짜 미지정'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('calendar-task-undated')));
      expect(openedTask?.id, 'undated');
    },
  );

  testWidgets('fits a narrow screen with large text', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpCalendar(tester);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('주'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'full-width month/week controls and the task adjustment header pin while scrolling',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tasks = [for (var i = 0; i < 30; i++) task('task-$i', 15)];
      await pumpCalendar(tester);
      expect(find.text('캘린더'), findsNothing);
      final format = find.byKey(const ValueKey('calendar-format'));
      expect(tester.getSize(format).width, 328);
      expect(
        tester.getTopLeft(format).dy,
        lessThan(
          tester
              .getTopLeft(find.byKey(const ValueKey('calendar-navigation')))
              .dy,
        ),
      );
      final ordered = [
        find.byTooltip('오늘로 이동'),
        find.byTooltip('이전 기간'),
        find.byKey(const ValueKey('calendar-current-period')),
        find.byTooltip('다음 기간'),
        find.byTooltip('선택한 날짜에 일정 추가'),
      ];
      for (var i = 1; i < ordered.length; i++) {
        expect(
          tester.getCenter(ordered[i - 1]).dx,
          lessThan(tester.getCenter(ordered[i]).dx),
        );
      }
      final calendar = find.byType(TableCalendar<Task>);
      final header = find.byKey(const ValueKey('calendar-task-header'));
      expect(
        tester.getTopLeft(header).dy,
        greaterThan(tester.getBottomLeft(calendar).dy - 1),
      );
      final scroll = find
          .descendant(
            of: find.byKey(const ValueKey('calendar-scroll')),
            matching: find.byType(Scrollable),
          )
          .first;
      tester.state<ScrollableState>(scroll).position.jumpTo(600);
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(header).dy, 0);
      expect(tester.getSize(header).height, 48);
      await tester.tap(find.byTooltip('캘린더 보기 조정'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, '개인 일정'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'e-campus 일정'), findsOneWidget);
      expect(find.byType(SwitchListTile), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(header).dy, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('empty and loading calendar lists retain the same task header', (
    tester,
  ) async {
    tasks = [];
    await pumpCalendar(tester);
    expect(find.byKey(const ValueKey('calendar-task-header')), findsOneWidget);
    expect(find.text('할 일이 없습니다.'), findsOneWidget);
    await pumpCalendar(tester, isLoading: true);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('할 일이 없습니다.'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Task task(
  String id,
  int? day, {
  TaskStatus status = TaskStatus.active,
  TaskOrigin origin = TaskOrigin.personal,
}) => Task(
  id: id,
  title: id,
  origin: origin,
  status: status,
  dueDate: day == null ? null : DateTime(2026, 6, day, 14),
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);
