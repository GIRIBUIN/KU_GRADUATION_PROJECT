import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ku_task_management/data/local/app_database.dart'
    show AppDatabase;
import 'package:ku_task_management/data/models/task_models.dart';
import 'package:ku_task_management/data/repositories/drift_notification_repository.dart';
import 'package:ku_task_management/data/services/widget_workspace_controller.dart';
import 'package:ku_task_management/presentation/services/local_notification_service.dart';

class _Notifications extends LocalNotificationService {
  bool fail = false;
  final cancelled = <String>[];
  final scheduled = <String>[];
  @override
  Future<void> cancelTaskNotification(String taskId) async {
    if (fail) throw StateError('OS permission');
    cancelled.add(taskId);
  }

  @override
  Future<void> scheduleTaskNotification({
    required Task task,
    required NotificationSetting setting,
    bool requestPermissionBeforeScheduling = false,
  }) async {
    if (fail) throw StateError('OS permission');
    scheduled.add(task.id);
  }
}

void main() {
  late AppDatabase database;
  late WidgetWorkspaceController controller;
  late _Notifications notifications;
  final today = DateTime(2026, 10, 15, 15);
  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    notifications = _Notifications();
    controller = WidgetWorkspaceController(
      database,
      WidgetKind.today,
      now: () => today,
      notifications: notifications,
    );
  });
  tearDown(() async {
    controller.dispose();
    await database.close();
  });

  test(
    'widget saves shared data and relations, then completes, undoes, deletes and restores',
    () async {
      await controller.addTag('학업');
      await controller.addFolder('학교');
      final tag = controller.tags.single.id;
      final folder = controller.folders.single.id;
      await controller.save(
        title: '위젯 입력',
        due: today,
        memo: '메모 유지',
        tagIds: [tag],
        folderId: folder,
        priority: TaskPriority.high,
        changeReminder: true,
        reminderMinutes: 30,
      );
      final task = controller.all.single;
      expect(task.memo, '메모 유지');
      expect(task.tagIds, [tag]);
      expect(task.folderIds, [folder]);
      expect(
        (await DriftNotificationRepository(
          database: database,
        ).getByTaskId(task.id))!.daysBeforeDue,
        30,
      );
      expect(notifications.scheduled, [task.id]);
      await controller.status(task, TaskStatus.completed);
      expect(controller.all.single.status, TaskStatus.completed);
      expect(notifications.cancelled, contains(task.id));
      await controller.undo();
      expect(controller.all.single.status, TaskStatus.active);
      expect(notifications.scheduled.length, 2);
      await controller.status(controller.all.single, TaskStatus.deleted);
      expect(controller.select(), isEmpty);
      await controller.configure({'period': 'trash'});
      expect(controller.select().single.id, task.id);
      await controller.status(controller.all.single, TaskStatus.active);
      expect(controller.select(), isEmpty);
    },
  );

  test(
    'academic deadlines and source identity survive native widget editing',
    () async {
      final original = Task(
        id: 'academic',
        origin: TaskOrigin.ecampus,
        status: TaskStatus.active,
        title: '원본 과제',
        dueDate: today,
        createdAt: today,
        updatedAt: today,
        ecampus: EcampusSyncMetadata(
          sourceKey: 'course-task',
          sourceDueDate: today,
          sourceCourse: '자료구조',
        ),
      );
      await controller.tasks.createTask(original);
      await expectLater(
        controller.save(
          existing: original,
          title: '과제',
          due: today.add(const Duration(days: 1)),
        ),
        throwsStateError,
      );
      await controller.save(
        existing: original,
        title: '과제 메모',
        due: today,
        memo: '개인 메모',
      );
      expect(controller.all.single.ecampus!.sourceKey, 'course-task');
      expect(controller.all.single.ecampus!.sourceDueDate, today);
      await controller.status(controller.all.single, TaskStatus.excluded);
      expect(controller.all.single.ecampus!.sourceKey, 'course-task');
    },
  );

  test('undo refuses to overwrite another app window edit', () async {
    await controller.save(title: '공유 일정', due: today);
    final task = controller.all.single;
    await controller.status(task, TaskStatus.completed);
    await controller.tasks.updateTaskStatus(task.id, TaskStatus.deleted);
    await expectLater(controller.undo(), throwsStateError);
    expect(
      (await controller.tasks.getTaskById(task.id))!.status,
      TaskStatus.deleted,
    );
  });

  test(
    'today keeps elapsed deadlines; calendar selection ignores list period and respects filters',
    () async {
      await controller.save(title: '오늘 오전', due: DateTime(2026, 10, 15, 9));
      await controller.save(title: '내일', due: DateTime(2026, 10, 16));
      await controller.save(title: '기한 없음');
      expect(controller.select().map((task) => task.title), ['오늘 오전']);
      expect(controller.select(day: DateTime(2026, 10, 16)).single.title, '내일');
      await controller.configure({'period': 'all'});
      expect(controller.select().length, 3);
      controller.search = '없음';
      expect(controller.select().single.title, '기한 없음');
    },
  );

  test(
    'themes and opacity persist separately for today, weekly and calendar',
    () async {
      await controller.configure({'theme': 'glass', 'opacity': .7});
      final calendar = WidgetWorkspaceController(database, WidgetKind.calendar);
      addTearDown(calendar.dispose);
      await calendar.load();
      expect(calendar.theme, WidgetTheme.light);
      await calendar.configure({'theme': 'dark', 'opacity': 1});
      await controller.load();
      expect(controller.theme, WidgetTheme.glass);
      expect(controller.opacity, .7);
      await calendar.load();
      expect(calendar.theme, WidgetTheme.dark);
    },
  );

  test(
    'clearing a due date clears its reminder without opening advanced controls',
    () async {
      await controller.save(
        title: '알림 일정',
        due: today,
        changeReminder: true,
        reminderMinutes: 60,
      );
      final task = controller.all.single;
      await controller.save(existing: task, title: task.title);
      expect(controller.all.single.dueDate, isNull);
      expect(
        await DriftNotificationRepository(
          database: database,
        ).getByTaskId(task.id),
        isNull,
      );
    },
  );
  test('weekly range matches existing app Monday through Sunday', () async {
    for (final day in [11, 12, 18, 19]) {
      await controller.save(title: '$day일', due: DateTime(2026, 10, day, 12));
    }
    await controller.configure({'period': 'week'});
    expect(controller.select().map((task) => task.title), ['12일', '18일']);
  });

  test(
    'urgent filter excludes past deadlines and honors app urgency setting',
    () async {
      for (final day in [14, 16, 18, 19]) {
        await controller.save(title: '$day일', due: DateTime(2026, 10, day, 12));
      }
      await controller.configure({'period': 'urgent'});
      expect(controller.select().map((task) => task.title), ['16일', '18일']);
    },
  );
  test('a reminder failure never makes a saved task look unsaved', () async {
    notifications.fail = true;
    await controller.save(
      title: '저장 완료',
      due: today,
      changeReminder: true,
      reminderMinutes: 60,
    );
    expect(controller.all.single.title, '저장 완료');
    expect(controller.notice, contains('일정은 저장'));
  });

  test('an editor cannot overwrite another window status change', () async {
    await controller.save(title: '처음 제목', due: today);
    final original = controller.all.single;
    await controller.tasks.updateTaskStatus(original.id, TaskStatus.completed);
    await expectLater(
      controller.save(existing: original, title: '다른 제목', due: today),
      throwsStateError,
    );
    final task = await controller.tasks.getTaskById(original.id);
    expect(task!.title, '처음 제목');
    expect(task.status, TaskStatus.completed);
  });
}
