import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ku_task_management/core/theme/app_theme.dart';
import 'package:ku_task_management/data/models/task_models.dart';
import 'package:ku_task_management/presentation/widgets/task_list_row.dart';

void main() {
  setUpAll(() => initializeDateFormatting('ko_KR'));
  for (final scale in [1.0, 1.5, 2.0]) {
    testWidgets(
      'split deadline and priority backgrounds retain row actions at $scale',
      (tester) async {
        tester.view.physicalSize = const Size(360, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final at = DateTime.now();
        final due = DateTime(at.year, at.month, at.day, 23, 59);
        final colors = <Color>{};
        for (final priority in [
          TaskPriority.high,
          TaskPriority.medium,
          TaskPriority.low,
          null,
        ]) {
          var opened = false;
          var toggled = false;
          final task = Task(
            id: 'row',
            title: '긴 과제 제목도 다음 줄로 이어서 읽을 수 있어야 합니다',
            origin: TaskOrigin.personal,
            status: TaskStatus.active,
            priority: priority,
            dueDate: due,
            createdAt: at,
            updatedAt: at,
          );
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.light(),
              home: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: Scaffold(
                  body: buildTaskListRow(
                    key: const ValueKey('task-row'),
                    task: task,
                    leading: Checkbox(
                      value: false,
                      onChanged: (_) => toggled = true,
                    ),
                    onTap: () => opened = true,
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final row = find.byKey(const ValueKey('task-row'));
          final date = find.descendant(of: row, matching: find.text('D-day'));
          final time = find.descendant(of: row, matching: find.text('23:59'));
          expect(
            tester.getBottomLeft(date).dy,
            lessThanOrEqualTo(tester.getTopLeft(time).dy),
          );
          expect(
            tester.getRect(time).right,
            lessThanOrEqualTo(tester.getRect(row).right),
          );
          final title = find.descendant(
            of: row,
            matching: find.text(task.title),
          );
          expect(
            tester.renderObject<RenderParagraph>(title).didExceedMaxLines,
            isFalse,
          );
          expect(find.text('높음'), findsNothing);
          expect(find.text('중간'), findsNothing);
          expect(find.text('낮음'), findsNothing);
          final background = tester
              .element(row)
              .findAncestorWidgetOfExactType<Material>()!
              .color!;
          if (priority == null) {
            expect(background, Colors.transparent);
          } else {
            expect(background.a, greaterThan(0));
            colors.add(background);
            final semantics = tester
                .element(row)
                .findAncestorWidgetOfExactType<Semantics>();
            expect(semantics!.properties.label, contains('우선순위'));
          }
          await tester.tap(title);
          expect(opened, isTrue);
          await tester.tap(find.byType(Checkbox));
          expect(toggled, isTrue);
          expect(tester.takeException(), isNull);
        }
        expect(colors, hasLength(3));
      },
    );
  }

  testWidgets('relative deadline uses calendar dates and preserves the time', (
    tester,
  ) async {
    final now = DateTime.now();
    for (final (offset, label, hour, minute) in [
      (-1, 'D+1', 23, 59),
      (0, 'D-day', 0, 1),
      (1, 'D-1', 0, 1),
      (10, 'D-10', 12, 30),
      (-10, 'D+10', 12, 30),
    ]) {
      final due = DateTime(now.year, now.month, now.day + offset, hour, minute);
      final task = Task(
        id: 'relative',
        title: '상대 마감',
        origin: TaskOrigin.personal,
        status: TaskStatus.active,
        dueDate: due,
        createdAt: now,
        updatedAt: now,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: buildTaskListRow(
              key: const ValueKey('task-row'),
              task: task,
              leading: const Checkbox(value: false, onChanged: null),
              onTap: null,
            ),
          ),
        ),
      );
      expect(find.text(label), findsOneWidget);
      expect(
        find.text(
          '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
        ),
        findsOneWidget,
      );
      expect(find.text('${due.month}/${due.day}'), findsNothing);
      expect(task.dueDate, due);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
    'undated completed task keeps completion styling and no invented date',
    (tester) async {
      final at = DateTime.now();
      final task = Task(
        id: 'undated',
        title: '마감 없는 완료',
        origin: TaskOrigin.personal,
        status: TaskStatus.completed,
        priority: TaskPriority.high,
        createdAt: at,
        updatedAt: at,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: buildTaskListRow(
              key: const ValueKey('task-row'),
              task: task,
              leading: const Checkbox(value: true, onChanged: null),
              onTap: null,
            ),
          ),
        ),
      );
      expect(find.text('마감 없음'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text(task.title)).style!.decoration,
        TextDecoration.lineThrough,
      );
      expect(find.text('높음'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
