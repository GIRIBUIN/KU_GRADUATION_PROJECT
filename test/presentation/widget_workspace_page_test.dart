import 'dart:async';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ku_task_management/data/local/app_database.dart'
    show AppDatabase;
import 'package:ku_task_management/data/services/widget_workspace_controller.dart';
import 'package:ku_task_management/presentation/widgets/widget_workspace_page.dart';
import 'package:ku_task_management/presentation/widgets/workspace_calendar.dart';

class _Screens extends ScreenRetrieverPlatform {
  static const display = Display(
    id: 'test',
    size: Size(800, 600),
    visiblePosition: Offset.zero,
    visibleSize: Size(800, 560),
  );
  @override
  Future<List<Display>> getAllDisplays() async => [display];
  @override
  Future<Display> getPrimaryDisplay() async => display;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('window readiness cannot block app startup', () async {
    final ready = Completer<void>();
    final focused = Completer<void>();
    final calls = <String>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(const MethodChannel('window_manager'), (
      call,
    ) async {
      calls.add(call.method);
      if (call.method == 'focus') focused.complete();
      if (call.method == 'waitUntilReadyToShow') await ready.future;
      if (call.method.startsWith('is')) return false;
      return null;
    });
    await prepareWidgetWindow().timeout(const Duration(seconds: 1));
    expect(ready.isCompleted, isFalse);
    ready.complete();
    await focused.future.timeout(const Duration(seconds: 2));
    expect(calls, contains('show'));
    messenger.setMockMethodCallHandler(
      const MethodChannel('window_manager'),
      null,
    );
  });
  testWidgets(
    'calendar header expands and a desktop blur returns to its compact size',
    (tester) async {
      final previousScreens = ScreenRetrieverPlatform.instance;
      ScreenRetrieverPlatform.instance = _Screens();
      addTearDown(() => ScreenRetrieverPlatform.instance = previousScreens);
      final calls = <MethodCall>[];
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        const MethodChannel('window_manager'),
        (call) async {
          calls.add(call);
          return call.method == 'getBounds'
              ? {'x': 0.0, 'y': 0.0, 'width': 360.0, 'height': 300.0}
              : null;
        },
      );
      final database = AppDatabase(NativeDatabase.memory());
      final controller = WidgetWorkspaceController(
        database,
        WidgetKind.calendar,
      );
      final key = GlobalKey<WidgetWorkspacePageState>();
      await controller.load();
      await tester.pumpWidget(
        MaterialApp(
          home: WidgetWorkspacePage(
            key: key,
            controller: controller,
            windowed: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('+ 추가'), findsNothing);
      final now = DateTime.now();
      await tester.tap(find.text('${now.year}년 ${now.month}월'));
      await tester.pumpAndSettle();
      expect(find.text('+ 추가'), findsOneWidget);
      key.currentState!.onWindowBlur();
      await tester.pumpAndSettle();
      expect(find.text('+ 추가'), findsNothing);
      final sizes = calls
          .where((call) => call.method == 'setBounds')
          .map((call) => call.arguments as Map)
          .toList();
      expect(sizes.first['width'], 420);
      expect(sizes.first['y'], greaterThanOrEqualTo(0));
      expect(
        (sizes.first['y'] as num) + (sizes.first['height'] as num),
        lessThanOrEqualTo(560),
      );
      expect(sizes.last['width'], 360);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      await database.close();
      messenger.setMockMethodCallHandler(
        const MethodChannel('window_manager'),
        null,
      );
    },
  );
  testWidgets(
    'basic form stays compact and saves inside the widget workspace',
    (tester) async {
      final database = AppDatabase(NativeDatabase.memory());
      final controller = WidgetWorkspaceController(database, WidgetKind.today);
      await controller.load();
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 420,
            height: 620,
            child: WidgetWorkspacePage(controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(WorkspaceCalendar), findsNothing);
      await tester.tap(find.text('+ 추가'));
      await tester.pumpAndSettle();
      expect(
        tester
            .getSize(find.byKey(const ValueKey('due-two-week-viewport')))
            .height,
        72,
      );
      expect(find.text('우선순위'), findsNothing);
      final more = tester.getRect(find.ancestor(of: find.text('더 보기 ▾'), matching: find.byType(TextButton)));
      final save = tester.getRect(find.ancestor(of: find.text('저장'), matching: find.byType(FilledButton)));
      expect(save.top - more.bottom, lessThanOrEqualTo(8));
      await tester.enterText(
        find.byKey(const ValueKey('widget-title')),
        '팝업에서 저장',
      );
      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();
      expect(controller.all.single.title, '팝업에서 저장');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      await database.close();
    },
  );

  testWidgets(
    'calendar fits one week at minimum height and a full month when enlarged',
    (tester) async {
      for (final height in [120.0, 400.0]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Material(
              child: Center(
                child: SizedBox(
                  width: 220,
                  height: height,
                  child: WorkspaceCalendar(
                    month: DateTime(2026, 10),
                    tasks: const [],
                    adaptive: true,
                    onDay: (_) {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(find.byType(InkWell), findsNWidgets(height == 120 ? 7 : 35));
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'browsing dates never changes the selection until a date is tapped',
    (tester) async {
      var calls = 0;
      final due = DateTime(2026, 10, 15, 23, 59);
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Center(
              child: SizedBox(
                width: 360,
                child: TwoWeekDuePicker(value: due, onChanged: (_) => calls++),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.drag(
        find.byKey(const ValueKey('due-two-week-viewport')),
        const Offset(0, -72),
      );
      await tester.pumpAndSettle();
      expect(calls, 0);
      expect(
        tester
            .getSize(find.byKey(const ValueKey('due-two-week-viewport')))
            .height,
        72,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
