import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:path_provider/path_provider.dart';

import '../models/task_models.dart';
import '../models/today_widget_data.dart';
import '../models/weekly_widget_data.dart';
import '../repositories/settings_repository.dart';
import '../repositories/tag_repository.dart';
import '../repositories/task_repository.dart';
import 'home_task_summary.dart';
import 'widget_format.dart';
import 'widget_today_selection.dart';
import 'widget_week_selection.dart';
import 'apple_widget_bridge.dart';

/// Flutter → 위젯 DB 경로/호환용 JSON 저장 및 오늘/주간/캘린더 위젯 갱신.
/// Android workspace providers read the shared DB directly for offline edits.
class WidgetUpdateService {
  WidgetUpdateService({
    required TaskRepository taskRepository,
    required SettingsRepository settingsRepository,
    required TagRepository tagRepository,
    DateTime Function()? now,
  }) : _taskRepository = taskRepository,
       _settingsRepository = settingsRepository,
       _tagRepository = tagRepository,
       _now = now ?? DateTime.now;

  static const todayAndroidProviderName = 'ScheduleWidgetProvider';
  static const weeklyAndroidProviderName = 'WeeklyScheduleWidgetProvider';
  static const calendarAndroidProviderName = 'CalendarWidgetProvider';
  static const widgetRefreshRequiredKey = 'widget_refresh_required';
  static const widgetPendingCompletionsKey = 'widget_pending_completions';
  static const widgetPendingUncompletionsKey = 'widget_pending_uncompletions';
  static const widgetDatabasePathKey = 'widget_db_path';

  final TaskRepository _taskRepository;
  final SettingsRepository _settingsRepository;
  final TagRepository _tagRepository;
  final DateTime Function() _now;

  /// 이전 버전의 주간 위젯에 남은 완료/해제 요청을 반영한다.
  /// 새 Android 위젯의 변경은 즉시 같은 DB에 기록된다.
  Future<void> applyPendingWidgetCompletions() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    final uncompletionIds = await _readPendingTaskIds(
      widgetPendingUncompletionsKey,
    );
    for (final taskId in uncompletionIds) {
      final task = await _taskRepository.getTaskById(taskId);
      if (task == null || task.status != TaskStatus.completed) {
        continue;
      }
      await _taskRepository.updateTaskStatus(taskId, TaskStatus.active);
    }
    await HomeWidget.saveWidgetData(widgetPendingUncompletionsKey, null);

    final completionIds = await _readPendingTaskIds(
      widgetPendingCompletionsKey,
    );
    for (final taskId in completionIds) {
      final task = await _taskRepository.getTaskById(taskId);
      if (task == null || task.status != TaskStatus.active) {
        continue;
      }
      await _taskRepository.updateTaskStatus(taskId, TaskStatus.completed);
    }
    await HomeWidget.saveWidgetData(widgetPendingCompletionsKey, null);
  }

  Future<List<String>> _readPendingTaskIds(String key) async {
    final raw = await HomeWidget.getWidgetData<String>(key, defaultValue: '');
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const [];
      }
      return decoded
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  /// 기존 두 위젯 JSON을 저장하고 세 Android Provider를 업데이트한다.
  Future<void> refresh() async {
    if (AppleWidgetBridge.supported) {
      await AppleWidgetBridge.reload();
      return;
    }
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    await applyPendingWidgetCompletions();
    // Source dates or statuses can also change during an in-app e-campus sync.
    // Reconcile widget-owned alarms before publishing the refreshed snapshots.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        await const MethodChannel(
          'ku.todo/widget-reminders',
        ).invokeMethod<void>('reconcile');
      } on MissingPluginException {
        // Test hosts and older/platforms without the Android workspace bridge.
      }
    }
    final now = _now();
    final documentsDir = await getApplicationDocumentsDirectory();
    await HomeWidget.saveWidgetData(
      widgetDatabasePathKey,
      '${documentsDir.path}/ku_task_management.sqlite',
    );

    final todayData = await buildTodayWidgetData(now: now);
    await HomeWidget.saveWidgetData(
      TodayWidgetData.storageKey,
      todayData.toJsonString(),
    );
    await HomeWidget.updateWidget(androidName: todayAndroidProviderName);

    final weeklyData = await buildWeeklyWidgetData(now: now);
    await HomeWidget.saveWidgetData(
      WeeklyWidgetData.storageKey,
      weeklyData.toJsonString(),
    );
    await HomeWidget.updateWidget(androidName: weeklyAndroidProviderName);
    await HomeWidget.updateWidget(androidName: calendarAndroidProviderName);
  }

  static Future<bool> consumeWidgetChanges() async {
    if (AppleWidgetBridge.supported) return AppleWidgetBridge.consumeChanges();
    if (kIsWeb) return false;
    if (defaultTargetPlatform != TargetPlatform.android) return true;
    final changed = await HomeWidget.getWidgetData<bool>(
      widgetRefreshRequiredKey,
      defaultValue: false,
    );
    if (changed == true) {
      await HomeWidget.saveWidgetData(widgetRefreshRequiredKey, null);
    }
    return changed == true;
  }

  /// 오늘 할 일정 위젯(ScheduleWidgetProvider)용 스냅샷.
  Future<TodayWidgetData> buildTodayWidgetData({DateTime? now}) async {
    final current = now ?? _now();
    final tasks = await _taskRepository.getTasks(includeArchived: false);
    final settings = await _settingsRepository.getSettings();
    final tagsById = {
      for (final tag in await _tagRepository.getTags()) tag.id: tag,
    };
    final summary = HomeTaskSummary.fromTasks(
      tasks: tasks,
      now: current,
      urgentDueDays: settings.urgentDueDays,
    );
    final selectedTasks = selectWidgetTasks(summary);

    return TodayWidgetData(
      headerDateLabel: formatWidgetHeaderDate(current),
      tasks: selectedTasks
          .map(
            (task) => TodayWidgetTaskSnapshot(
              id: task.id,
              title: task.title,
              timeLabel: formatWidgetTime(task.dueDate),
              accentColorHex: accentColorForTask(task, tagsById: tagsById),
            ),
          )
          .toList(growable: false),
      todayCount: summary.todayTasks.length,
      updatedAt: current,
    );
  }

  /// 이번 주 일정 위젯(WeeklyScheduleWidgetProvider)용 스냅샷.
  Future<WeeklyWidgetData> buildWeeklyWidgetData({DateTime? now}) async {
    final current = now ?? _now();
    final week = weekWindowFor(current);
    final tasks = await _taskRepository.getTasks(includeArchived: true);
    final weekTasks = tasksForWeek(tasks, week);
    final selectedTasks = selectWidgetWeekTasks(weekTasks);
    final progress = weekProgressCounts(weekTasks);

    return WeeklyWidgetData(
      weekRangeLabel: formatWidgetWeekRange(week.start, week.end),
      completedCount: progress.completedCount,
      totalCount: progress.totalCount,
      tasks: selectedTasks
          .map((task) => _toWeeklySnapshot(task, now: current))
          .toList(growable: false),
      updatedAt: current,
    );
  }

  WeeklyWidgetTaskSnapshot _toWeeklySnapshot(
    Task task, {
    required DateTime now,
  }) {
    final dueDate = task.dueDate!;
    return WeeklyWidgetTaskSnapshot(
      id: task.id,
      title: task.title,
      categoryLabel: categoryLabelForTask(task),
      categoryBackgroundHex: categoryBackgroundHexForTask(task),
      categoryTextHex: categoryTextHexForTask(task),
      dueLabel: formatWidgetDueLabel(dueDate, now: now),
      dueColorHex: dueColorHexForDate(dueDate, now: now),
      isCompleted: isTaskCompletedForWidget(task),
    );
  }
}
