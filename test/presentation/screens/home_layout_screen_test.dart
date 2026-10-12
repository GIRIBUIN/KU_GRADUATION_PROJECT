import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ku_task_management/core/theme/app_theme.dart';
import 'package:ku_task_management/data/models/home_section.dart';
import 'package:ku_task_management/data/repositories/settings_repository.dart';
import 'package:ku_task_management/presentation/screens/settings/home_layout_screen.dart';

void main() {
  late _SettingsRepository repository;

  setUp(() => repository = _SettingsRepository());

  Future<void> openEditor(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push<AppSettings>(
                MaterialPageRoute(
                  builder: (_) => HomeLayoutScreen(
                    settings: repository.settings,
                    settingsRepository: repository,
                  ),
                ),
              ),
              child: const Text('Open editor'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open editor'));
    await tester.pumpAndSettle();
  }

  Finder sectionSwitch(HomeSection section) => find.descendant(
    of: find.byKey(ValueKey(section.id)),
    matching: find.byType(Switch),
  );

  testWidgets('toggles and drags sections, then saves only layout fields', (
    tester,
  ) async {
    await openEditor(tester);
    expect(
      tester.widget<Switch>(sectionSwitch(HomeSection.calendar)).value,
      false,
    );
    await tester.tap(sectionSwitch(HomeSection.todayTasks));
    await tester.tap(sectionSwitch(HomeSection.calendar));
    await tester.pumpAndSettle();

    final handle = find.descendant(
      of: find.byKey(const ValueKey('calendar')),
      matching: find.byType(ReorderableDragStartListener),
    );
    final start = tester.getCenter(handle);
    final target = tester.getTopLeft(find.byKey(const ValueKey('todayTasks')));
    final gesture = await tester.startGesture(start);
    await gesture.moveBy(const Offset(0, -30));
    await tester.pump();
    await gesture.moveTo(Offset(start.dx, target.dy - 80));
    await tester.pump(const Duration(milliseconds: 500));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.byKey(const ValueKey('calendar'))).dy,
      lessThan(tester.getTopLeft(find.byKey(const ValueKey('todayTasks'))).dy),
    );

    final todayHandle = find.descendant(
      of: find.byKey(const ValueKey('todayTasks')),
      matching: find.byType(ReorderableDragStartListener),
    );
    await tester.drag(todayHandle, const Offset(0, 350));
    await tester.pumpAndSettle();

    expect(repository.saveCount, 0);
    repository.settings = repository.settings.copyWith(
      urgentDueDays: 10,
      homeSelectedTagId: 'new-tag',
    );
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeLayoutScreen), findsNothing);
    expect(repository.settings.homeSectionOrder.first, HomeSection.calendar);
    expect(repository.settings.homeSectionOrder.last, HomeSection.todayTasks);
    expect(repository.settings.hiddenHomeSections, {HomeSection.todayTasks});
    expect(repository.settings.homeSelectedTagId, 'new-tag');
    expect(repository.settings.urgentDueDays, 10);
    expect(repository.saveCount, 1);
  });

  testWidgets('back discards edits and restore resets order and visibility', (
    tester,
  ) async {
    repository.settings = repository.settings.copyWith(
      homeSectionOrder: HomeSection.values.reversed.toList(),
      hiddenHomeSections: HomeSection.values.toSet(),
    );
    await openEditor(tester);
    await tester.tap(find.byTooltip('기본 구성으로 복원'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Switch>(sectionSwitch(HomeSection.todayTasks)).value,
      true,
    );
    expect(
      tester.widget<Switch>(sectionSwitch(HomeSection.calendar)).value,
      false,
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(repository.saveCount, 0);
    expect(repository.settings.hiddenHomeSections, HomeSection.values.toSet());

    await tester.tap(find.text('Open editor'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('기본 구성으로 복원'));
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(repository.settings.homeSectionOrder, HomeSection.values);
    expect(repository.settings.hiddenHomeSections, HomeSection.defaultHidden);
  });

  testWidgets('keeps edits after a failed save and permits retry', (
    tester,
  ) async {
    await openEditor(tester);
    await tester.tap(sectionSwitch(HomeSection.calendar));
    repository.failSave = true;
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeLayoutScreen), findsOneWidget);
    expect(find.text('홈 화면 구성을 저장하지 못했습니다. 다시 시도해 주세요.'), findsOneWidget);
    expect(
      tester.widget<Switch>(sectionSwitch(HomeSection.calendar)).value,
      true,
    );
    repository.failSave = false;
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(repository.settings.hiddenHomeSections, isEmpty);
  });

  testWidgets(
    'locks controls during save and handles small screens and large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await openEditor(tester);
      expect(tester.takeException(), isNull);
      repository.saveGate = Completer<void>();
      await tester.tap(find.text('저장'));
      await tester.pump();
      expect(
        tester.widget<Switch>(sectionSwitch(HomeSection.todayTasks)).onChanged,
        isNull,
      );
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      repository.saveGate!.complete();
      await tester.pumpAndSettle();
      expect(repository.saveCount, 1);
      expect(find.byType(HomeLayoutScreen), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

class _SettingsRepository implements SettingsRepository {
  AppSettings settings = const AppSettings(
    autoSyncEnabled: false,
    saveEcampusAccount: false,
    defaultNotificationEnabled: true,
    defaultNotificationDays: 60,
    defaultNotificationTime: 'relative',
    urgentDueDays: 3,
  );
  int saveCount = 0;
  bool failSave = false;
  Completer<void>? saveGate;

  @override
  Future<AppSettings> getSettings() async => settings;

  @override
  Future<AppSettings> saveSettings(AppSettings value) async {
    if (failSave) throw StateError('Save failed');
    await saveGate?.future;
    saveCount++;
    return settings = value;
  }
}
