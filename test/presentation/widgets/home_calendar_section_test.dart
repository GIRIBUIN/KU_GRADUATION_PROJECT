import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:ku_task_management/core/theme/app_theme.dart';
import 'package:ku_task_management/data/models/task_models.dart';
import 'package:ku_task_management/data/services/calendar_task_index.dart';
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

  Future<void> pumpCalendar(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko', 'KR'),
        supportedLocales: const [Locale('ko', 'KR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: HomeCalendarSection(
              initialDay: DateTime(2026, 6, 15),
              tasks: tasks,
              isLoading: false,
              onCreateTask: (day) => createdDay = day,
              onOpenTask: (task) => openedTask = task,
              onToggleTask: (task) => toggledTask = task,
              onDeleteTask: (task) => deletedTask = task,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'selects a date, adds on that date, opens and completes existing tasks',
    (tester) async {
      tester.view.physicalSize = const Size(600, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await pumpCalendar(tester);
      expect(find.text('6월 15일 (월) · 3개'), findsOneWidget);
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
      expect(find.text('6월 16일 (화) · 1개'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('calendar-task-personal')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('calendar-task-next')), findsOneWidget);
      await tester.tap(find.byTooltip('선택한 날짜에 일정 추가'));
      expect(createdDay, DateTime(2026, 6, 16));
      await tester.tap(find.byTooltip('next 일정 메뉴'));
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
      tasks = [task('refreshed', 15)];
      await pumpCalendar(tester);
      expect(find.text('6월 15일 (월) · 1개'), findsOneWidget);
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
      await tester.tap(find.byTooltip('완료 일정 숨기기'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('calendar-task-done')), findsNothing);
      await tester.tap(find.byTooltip('일정 유형: 전체 일정'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.ancestor(
          of: find.text('e-campus 일정'),
          matching: find.byType(CheckedPopupMenuItem<CalendarTaskSource>),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('calendar-task-personal')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('calendar-task-school')),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('일정 유형: e-campus 일정'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.ancestor(
          of: find.text('전체 일정'),
          matching: find.byType(CheckedPopupMenuItem<CalendarTaskSource>),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('날짜 미지정 (1)'));
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
