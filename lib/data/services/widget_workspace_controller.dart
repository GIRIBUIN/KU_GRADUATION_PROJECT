import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../local/app_database.dart';
import '../models/task_models.dart' as model;
import '../repositories/drift_folder_repository.dart';
import '../repositories/drift_sub_task_repository.dart';
import '../repositories/drift_tag_repository.dart';
import '../repositories/drift_task_repository.dart';
import '../repositories/drift_notification_repository.dart';
import '../repositories/drift_settings_repository.dart';
import '../../presentation/services/local_notification_service.dart';
import 'apple_widget_bridge.dart';

enum WidgetKind { today, week, calendar }

enum WidgetTheme { light, dark, gray, glass }

class WidgetWorkspaceController extends ChangeNotifier {
  WidgetWorkspaceController(
    this.database,
    this.kind, {
    DateTime Function()? now,
    this.notifications,
  }) : now = now ?? DateTime.now,
       tasks = DriftTaskRepository(database: database),
       tagRepository = DriftTagRepository(database: database),
       folderRepository = DriftFolderRepository(database: database),
       subTasks = DriftSubTaskRepository(database: database);

  final AppDatabase database;
  final WidgetKind kind;
  final DateTime Function() now;
  final DriftTaskRepository tasks;
  final DriftTagRepository tagRepository;
  final DriftFolderRepository folderRepository;
  final DriftSubTaskRepository subTasks;
  final LocalNotificationService? notifications;
  List<model.Task> all = [];
  List<model.Tag> tags = [];
  List<model.Folder> folders = [];
  Map<String, dynamic> options = {};
  Set<String> pins = {};
  String search = '';
  int urgentDays = 3;
  int? defaultReminderMinutes;
  String? notice;
  String? error;
  bool _loading = false;
  bool _disposed = false;
  model.Task? _undo;
  model.Task? _undoExpected;

  String get title => switch (kind) {
    WidgetKind.today => '오늘 할 일정',
    WidgetKind.week => '이번 주 일정',
    WidgetKind.calendar => '캘린더',
  };
  WidgetTheme get theme => WidgetTheme.values.firstWhere(
    (value) => value.name == options['theme'],
    orElse: () => WidgetTheme.light,
  );
  double get opacity =>
      ((options['opacity'] as num?)?.toDouble() ?? 1).clamp(.2, 1);
  String get period =>
      options['period'] as String? ??
      (kind == WidgetKind.calendar ? 'all' : kind.name);

  Future<void> load() async {
    if (_loading || _disposed) return;
    _loading = true;
    try {
      all = await tasks.getTasks(includeArchived: true);
      tags = await tagRepository.getTags();
      folders = await folderRepository.getFolders();
      final settings = await DriftSettingsRepository(
        database: database,
      ).getSettings();
      urgentDays = settings.urgentDueDays;
      defaultReminderMinutes = settings.defaultNotificationEnabled
          ? settings.defaultNotificationDays
          : null;
      options = await _readJson('widget_options_${kind.name}');
      pins = ((await _readJson('widget_pins'))['ids'] as List? ?? [])
          .cast<String>()
          .toSet();
      error = null;
    } catch (exception) {
      error = '일정을 불러오지 못했습니다: $exception';
    } finally {
      _loading = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<Map<String, dynamic>> _readJson(String key) async {
    final row = await (database.select(
      database.appSettings,
    )..where((row) => row.key.equals(key))).getSingleOrNull();
    if (row == null) return {};
    final decoded = jsonDecode(row.value);
    return decoded is Map<String, dynamic> ? decoded : {};
  }

  Future<void> _writeJson(String key, Map<String, dynamic> value) async {
    await database
        .into(database.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: key,
            value: jsonEncode(value),
            updatedAt: now(),
          ),
        );
  }

  Future<void> configure(Map<String, dynamic> changes) async {
    options = {...options, ...changes};
    await _writeJson('widget_options_${kind.name}', options);
    await _changed();
  }

  List<model.Task> select({DateTime? day, bool includeCompleted = false}) {
    final today = DateTime(now().year, now().month, now().day);
    final week = DateTime(
      today.year,
      today.month,
      today.day - today.weekday + 1,
    );
    final cutoff = DateTime(
      today.year,
      today.month,
      today.day + urgentDays + 1,
    );
    final result = all.where((task) {
      final trash =
          task.status == model.TaskStatus.deleted ||
          task.status == model.TaskStatus.excluded;
      if (period == 'trash' ? !trash : trash) return false;
      if (!includeCompleted &&
          options['showCompleted'] != true &&
          task.status == model.TaskStatus.completed) {
        return false;
      }
      if (options['origin'] != null &&
          options['origin'] != 'all' &&
          task.origin.name != options['origin']) {
        return false;
      }
      if (options['tag'] != null && !(task.tagIds.contains(options['tag']))) {
        return false;
      }
      if (options['folder'] != null &&
          !(task.folderIds.contains(options['folder']))) {
        return false;
      }
      final due = task.dueDate;
      if (day != null) {
        if (due == null || !sameDay(due, day)) return false;
      } else {
        switch (period) {
          case 'today':
            if (due == null || !sameDay(due, today)) return false;
          case 'week':
            if (due == null ||
                due.isBefore(week) ||
                !due.isBefore(DateTime(week.year, week.month, week.day + 7))) {
              return false;
            }
          case 'overdue':
            if (due == null ||
                !due.isBefore(now()) ||
                task.status != model.TaskStatus.active) {
              return false;
            }
          case 'urgent':
            if (due == null ||
                due.isBefore(now()) ||
                !due.isBefore(cutoff) ||
                task.status != model.TaskStatus.active) {
              return false;
            }
          case 'pinned':
            if (!pins.contains(task.id)) return false;
        }
      }
      final query = search.trim().toLowerCase();
      return query.isEmpty ||
          '${task.title} ${task.memo ?? ''} ${task.ecampus?.sourceCourse ?? ''}'
              .toLowerCase()
              .contains(query);
    }).toList();
    result.sort((a, b) {
      final pin = (pins.contains(b.id) ? 1 : 0) - (pins.contains(a.id) ? 1 : 0);
      if (pin != 0) return pin;
      if (options['sort'] == 'order') return a.sortOrder.compareTo(b.sortOrder);
      if (options['sort'] == 'priority') {
        final priority = (a.priority?.index ?? 3).compareTo(
          b.priority?.index ?? 3,
        );
        if (priority != 0) return priority;
      }
      return (a.dueDate ?? DateTime(9999)).compareTo(
        b.dueDate ?? DateTime(9999),
      );
    });
    return result;
  }

  Future<void> save({
    model.Task? existing,
    required String title,
    DateTime? due,
    String memo = '',
    model.TaskPriority? priority,
    List<String> tagIds = const [],
    String? folderId,
    bool changeReminder = false,
    int? reminderMinutes,
  }) async {
    if (title.trim().isEmpty) throw ArgumentError('제목을 입력해주세요.');
    if (existing?.isEcampus == true && due != existing!.dueDate) {
      throw StateError('학업 일정의 원본 마감은 변경할 수 없습니다.');
    }
    if (existing != null) {
      final current = await tasks.getTaskById(existing.id);
      if (current == null || _fingerprint(current) != _fingerprint(existing)) {
        throw StateError('다른 창에서 변경된 일정입니다. 새로 열어주세요.');
      }
    }
    final updated = model.Task(
      id: existing?.id ?? newId(),
      origin: existing?.origin ?? model.TaskOrigin.personal,
      status: existing?.status ?? model.TaskStatus.active,
      title: title.trim(),
      dueDate: due,
      priority: priority,
      memo: memo,
      tagIds: tagIds,
      folderIds: folderId == null ? [] : [folderId],
      createdAt: existing?.createdAt ?? now(),
      updatedAt: now(),
      parentTaskId: existing?.parentTaskId,
      ecampus: existing?.ecampus,
      sortOrder: existing?.sortOrder ?? -1,
      completedAt: existing?.completedAt,
      deletedAt: existing?.deletedAt,
    );
    _undo = null;
    final saved = existing == null
        ? await tasks.createTask(updated)
        : await tasks.updateTask(updated);
    _undoExpected = null;
    final reminders = DriftNotificationRepository(database: database);
    if (due == null || (changeReminder && reminderMinutes == null)) {
      await reminders.deleteByTaskId(saved.id);
    } else if (changeReminder && reminderMinutes != null) {
      await reminders.save(
        model.NotificationSetting(
          id: 'widget-${saved.id}',
          taskId: saved.id,
          enabled: true,
          daysBeforeDue: reminderMinutes,
          notifyTime: 'relative',
        ),
      );
    }
    await _reconcileReminder(saved);
    await _changed();
  }

  Future<void> status(model.Task task, model.TaskStatus status) async {
    _undo = task;
    _undoExpected = await tasks.updateTaskStatus(task.id, status);
    // A completed/deleted task must not retain an outstanding native reminder.
    if (status != model.TaskStatus.active) {
      await database.customStatement(
        'UPDATE notification_settings SET scheduled_at = NULL WHERE task_id = ?',
        [task.id],
      );
    }
    await _reconcileReminder(_undoExpected!);
    await _changed();
  }

  Future<void> undo() async {
    final old = _undo;
    if (old == null) return;
    final current = await tasks.getTaskById(old.id);
    if (current == null ||
        _fingerprint(current) != _fingerprint(_undoExpected!)) {
      throw StateError('다른 창에서 변경된 일정은 덮어쓰지 않습니다. 새로고침해주세요.');
    }
    _undo = null;
    await tasks.updateTask(old);
    await _reconcileReminder(old);
    await _changed();
  }

  String _fingerprint(model.Task task) => jsonEncode([
    task.status.name,
    task.title,
    task.dueDate?.millisecondsSinceEpoch,
    task.priority?.name,
    task.memo,
    task.tagIds.toList()..sort(),
    task.folderIds.toList()..sort(),
    task.updatedAt.millisecondsSinceEpoch,
    task.ecampus?.lastSyncedAt?.millisecondsSinceEpoch,
  ]);

  Future<void> _reconcileReminder(model.Task task) async {
    final service = notifications;
    if (service == null) return;
    try {
      final setting = await DriftNotificationRepository(
        database: database,
      ).getByTaskId(task.id);
      if (setting == null || task.status != model.TaskStatus.active) {
        await service.cancelTaskNotification(task.id);
      } else {
        await service.scheduleTaskNotification(
          task: task,
          setting: setting,
          requestPermissionBeforeScheduling: true,
        );
      }
    } catch (_) {
      notice = '일정은 저장되었지만 알림을 설정하지 못했습니다. OS 알림 권한을 확인해주세요.';
    }
  }

  Future<void> pin(model.Task task) async {
    if (!pins.remove(task.id)) pins.add(task.id);
    await _writeJson('widget_pins', {'ids': pins.toList()});
    await _changed();
  }

  Future<void> addTag(String name) async {
    if (name.trim().isEmpty) return;
    await tagRepository.createTag(
      model.Tag(
        id: newId(),
        name: name.trim(),
        color: '#1262D6',
        createdAt: now(),
        updatedAt: now(),
      ),
    );
    await _changed();
  }

  Future<void> addFolder(String name) async {
    if (name.trim().isEmpty) return;
    await folderRepository.createFolder(
      model.Folder(
        id: newId(),
        name: name.trim(),
        createdAt: now(),
        updatedAt: now(),
      ),
    );
    await _changed();
  }

  Future<void> _changed() async {
    await AppleWidgetBridge.reload();
    await load();
  }

  Future<void> startFocus(int minutes) => _writeJson('widget_focus', {
    'end': now().add(Duration(minutes: minutes)).millisecondsSinceEpoch,
  });

  Future<DateTime?> focusEnd() async {
    final end = (await _readJson('widget_focus'))['end'] as int?;
    return end == null ? null : DateTime.fromMillisecondsSinceEpoch(end);
  }

  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  static String newId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32).toRadixString(16)}';

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
