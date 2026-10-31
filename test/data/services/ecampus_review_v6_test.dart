import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ku_task_management/data/local/app_database.dart' as db;
import 'package:ku_task_management/data/models/ecampus_models.dart';
import 'package:ku_task_management/data/models/task_models.dart';
import 'package:ku_task_management/data/repositories/drift_folder_repository.dart';
import 'package:ku_task_management/data/repositories/drift_notification_repository.dart';
import 'package:ku_task_management/data/repositories/drift_settings_repository.dart';
import 'package:ku_task_management/data/repositories/drift_tag_repository.dart';
import 'package:ku_task_management/data/repositories/drift_task_repository.dart';
import 'package:ku_task_management/data/services/default_ecampus_sync_service.dart';
import 'package:ku_task_management/data/services/default_ecampus_todo_service.dart';
import 'package:ku_task_management/data/services/ecampus_auth_service.dart';
import 'package:ku_task_management/data/services/ecampus_sync_apply_service.dart';
import 'package:ku_task_management/data/services/ecampus_sync_classifier.dart';
import 'package:ku_task_management/data/services/ecampus_todo_client.dart';
import 'package:ku_task_management/data/services/ecampus_todo_parser.dart';
import 'package:ku_task_management/presentation/services/ecampus_notification_updater.dart';
import 'package:ku_task_management/presentation/services/local_notification_service.dart';

final _now = DateTime(2026, 10, 30, 12);
final _oldDue = DateTime(2027, 1, 1, 18);
final _newDue = DateTime(2027, 1, 2, 18);
const _source = 'course:item:report';

void main() {
  late db.AppDatabase database;
  late DriftTaskRepository tasks;
  late DriftNotificationRepository reminders;
  late _Notifications notifications;
  late List<Object> notificationErrors;
  late DefaultEcampusSyncApplyService apply;

  setUp(() {
    database = db.AppDatabase(NativeDatabase.memory());
    tasks = DriftTaskRepository(database: database, now: () => _now);
    reminders = DriftNotificationRepository(database: database);
    notifications = _Notifications();
    notificationErrors = [];
    final updater = EcampusNotificationUpdater(
      repository: reminders,
      notifications: notifications,
    );
    apply = DefaultEcampusSyncApplyService(
      taskRepository: tasks,
      tagRepository: DriftTagRepository(database: database),
      folderRepository: DriftFolderRepository(database: database),
      settingsRepository: DriftSettingsRepository(database: database),
      now: () => _now,
      afterTaskCommit: updater.afterCommit,
      onPostCommitError: notificationErrors.add,
    );
  });
  tearDown(() => database.close());

  Future<Task> seed(String id, {bool metadata = false}) async {
    if (metadata) {
      await DriftFolderRepository(database: database).createFolder(
        Folder(id: 'folder', name: 'Folder', createdAt: _now, updatedAt: _now),
      );
      await DriftTagRepository(database: database).createTag(
        Tag(
          id: 'tag',
          name: 'Tag',
          color: '#123456',
          createdAt: _now,
          updatedAt: _now,
        ),
      );
    }
    return tasks.createTask(
      Task(
        id: id,
        origin: TaskOrigin.ecampus,
        status: TaskStatus.active,
        title: 'My title',
        dueDate: _oldDue,
        memo: 'My memo',
        folderIds: metadata ? ['folder'] : [],
        tagIds: metadata ? ['tag'] : [],
        createdAt: _now,
        updatedAt: _now,
        ecampus: EcampusSyncMetadata(
          sourceKey: id == 'task' ? _source : 'course:$id:report',
          sourceTitle: 'Old source',
          sourceDueDate: _oldDue,
          sourceCourse: 'Course',
          sourceType: EcampusTaskType.report,
          lastSyncedAt: _now,
        ),
      ),
    );
  }

  Future<void> reminder(String id, {bool enabled = true}) => reminders.save(
    NotificationSetting(
      id: 'reminder-$id',
      taskId: id,
      enabled: enabled,
      daysBeforeDue: 30,
      notifyTime: 'relative',
    ),
  );

  SyncItem changed(Task task, {bool title = false, bool due = false}) =>
      SyncItem(
        kind: SyncItemKind.updateCandidate,
        existingTask: task,
        parsedTask: ParsedEcampusTask(
          sourceKey: _source,
          title: 'New source',
          course: 'Course',
          type: EcampusTaskType.report,
          dueDate: _newDue,
        ),
        applyTitle: title,
        applyDueDate: due,
      );

  SyncItem missing(
    Task task, [
    MissingItemDecision decision = MissingItemDecision.keep,
  ]) => SyncItem(
    kind: SyncItemKind.missing,
    existingTask: task,
    missingDecision: decision,
  );

  test(
    'NEW import, NEW ignore and replay preserve one source per item',
    () async {
      SyncItem item(String id) => SyncItem(
        kind: SyncItemKind.newItem,
        parsedTask: ParsedEcampusTask(
          sourceKey: 'course:$id:report',
          title: id,
          course: 'Course',
          type: EcampusTaskType.report,
        ),
      );
      await apply.importItems([item('a')]);
      await apply.importItems([item('a')]);
      await apply.excludeItems([item('b')]);
      expect(await database.select(database.tasks).get(), hasLength(1));
      final sources = await database.select(database.ecampusItems).get();
      expect(sources, hasLength(2));
      expect(
        sources
            .singleWhere((s) => s.externalKey == 'course:b:report')
            .importState,
        'ignored',
      );
      expect(notifications.scheduled, isEmpty);
    },
  );

  for (final (title, due) in [
    (false, false),
    (true, false),
    (false, true),
    (true, true),
  ]) {
    test(
      'CHANGED title=$title deadline=$due preserves user metadata',
      () async {
        final old = await seed('task', metadata: true);
        await apply.importItems([changed(old, title: title, due: due)]);
        final saved = (await tasks.getTaskById('task'))!;
        expect(saved.title, title ? 'New source' : 'My title');
        expect(saved.dueDate, due ? _newDue : _oldDue);
        expect(saved.memo, 'My memo');
        expect(saved.tagIds, ['tag']);
        expect(saved.folderIds, ['folder']);
        expect(saved.ecampus!.sourceTitle, 'New source');
        expect(saved.ecampus!.sourceDueDate, _newDue);
        expect(
          (await database.select(database.ecampusItems).get())
              .single
              .importState,
          'imported',
        );
      },
    );
  }

  for (final state in ['enabled', 'absent', 'disabled']) {
    test(
      'deadline change reschedules only an existing enabled reminder ($state)',
      () async {
        final old = await seed('task');
        if (state != 'absent') {
          await reminder('task', enabled: state == 'enabled');
        }
        notifications.onSchedule = (task) async {
          expect((await tasks.getTaskById(task.id))!.dueDate, _newDue);
          expect(
            await database.select(database.importSessions).get(),
            hasLength(1),
          );
        };
        await apply.importItems([changed(old, due: true)]);
        expect(
          notifications.scheduled,
          state == 'enabled' ? hasLength(1) : isEmpty,
        );
      },
    );
  }

  test(
    'keeping the deadline does not reschedule an existing reminder',
    () async {
      final old = await seed('task');
      await reminder('task');
      await apply.importItems([changed(old, title: true)]);
      expect(notifications.scheduled, isEmpty);
    },
  );

  test(
    'notification failure reports a post-commit error without undoing storage',
    () async {
      final old = await seed('task');
      await reminder('task');
      notifications.fail = true;
      final result = await apply.importItems([changed(old, due: true)]);
      expect(result.single.dueDate, _newDue);
      expect((await tasks.getTaskById('task'))!.dueDate, _newDue);
      expect(notificationErrors, hasLength(1));
      expect(
        await database.select(database.importSessions).get(),
        hasLength(1),
      );
    },
  );

  test('DB A,B / fetched A identifies only active B as MISSING', () async {
    final a = await seed('a');
    final b = await seed('b');
    final c = await seed('c');
    final d = await seed('d');
    await tasks.updateTaskStatus(c.id, TaskStatus.completed);
    await tasks.markDeleted(d.id);
    final result = const EcampusSyncClassifier().classify(
      parsedTasks: [
        ParsedEcampusTask(
          sourceKey: a.ecampus!.sourceKey,
          title: 'Old source',
          course: 'Course',
          type: EcampusTaskType.report,
          dueDate: _oldDue,
        ),
      ],
      existingTasks: await tasks.getTasks(
        origin: TaskOrigin.ecampus,
        includeArchived: true,
      ),
      syncedAt: _now,
    );
    expect(result.missingItems.single.existingTask!.id, b.id);
    expect(
      result.missingItems.single.missingDecision,
      MissingItemDecision.keep,
    );
    expect(result.importCandidates, isEmpty);
  });

  test(
    'MISSING default KEEP leaves task and original link untouched',
    () async {
      final old = await seed('task');
      final beforeTask = (await database.select(database.tasks).get()).single;
      final beforeSource =
          (await database.select(database.ecampusItems).get()).single;
      await apply.importItems([missing(old)]);
      expect((await database.select(database.tasks).get()).single, beforeTask);
      expect(
        (await database.select(database.ecampusItems).get()).single,
        beforeSource,
      );
      expect(notifications.cancelled, isEmpty);
    },
  );

  for (final decision in [
    MissingItemDecision.complete,
    MissingItemDecision.delete,
  ]) {
    test(
      'MISSING $decision uses normal status policy and cancels notification after commit',
      () async {
        final old = await seed('task');
        await reminder('task');
        await apply.importItems([missing(old, decision)]);
        final saved = (await tasks.getTaskById('task'))!;
        expect(
          saved.status,
          decision == MissingItemDecision.complete
              ? TaskStatus.completed
              : TaskStatus.deleted,
        );
        final source =
            (await database.select(database.ecampusItems).get()).single;
        expect(source.taskId, old.id);
        expect(source.importState, 'imported');
        expect(notifications.cancelled, ['task']);
        expect(saved.completedAt != null || saved.deletedAt != null, isTrue);
      },
    );
  }

  test(
    'a failure in MISSING batch rolls back every task and emits no OS calls',
    () async {
      final a = await seed('a');
      final b = await seed('b');
      await database.customStatement("""
      CREATE TRIGGER reject_b BEFORE UPDATE ON tasks
      WHEN NEW.id = 'b' AND NEW.completed_at IS NOT NULL
      BEGIN SELECT RAISE(ABORT, 'fixture failure'); END;
    """);
      await expectLater(
        apply.importItems([
          missing(a, MissingItemDecision.complete),
          missing(b, MissingItemDecision.complete),
        ]),
        throwsA(anything),
      );
      expect((await tasks.getTaskById('a'))!.status, TaskStatus.active);
      expect((await tasks.getTaskById('b'))!.status, TaskStatus.active);
      expect(await database.select(database.importSessions).get(), isEmpty);
      expect(notifications.cancelled, isEmpty);
      expect(notifications.scheduled, isEmpty);
    },
  );

  test(
    'a failed mixed change/MISSING batch does not reschedule a committed-looking deadline',
    () async {
      final old = await seed('task');
      final b = await seed('b');
      await reminder('task');
      await database.customStatement("""
      CREATE TRIGGER reject_b BEFORE UPDATE ON tasks WHEN NEW.id = 'b'
      BEGIN SELECT RAISE(ABORT, 'fixture failure'); END;
    """);
      await expectLater(
        apply.importItems([
          changed(old, due: true),
          missing(b, MissingItemDecision.delete),
        ]),
        throwsA(anything),
      );
      expect((await tasks.getTaskById('task'))!.dueDate, _oldDue);
      expect((await tasks.getTaskById('b'))!.status, TaskStatus.active);
      expect(notifications.scheduled, isEmpty);
      expect(notifications.cancelled, isEmpty);
    },
  );

  test('MISSING cannot overwrite a task edited after preview', () async {
    final old = await seed('task');
    await tasks.updateTaskStatus('task', TaskStatus.completed);
    await expectLater(
      apply.importItems([missing(old, MissingItemDecision.delete)]),
      throwsStateError,
    );
    expect((await tasks.getTaskById('task'))!.status, TaskStatus.completed);
    expect(await database.select(database.importSessions).get(), isEmpty);
  });

  final valid = """
    <div class="todo_wrap" onclick="goLecture('course','a','report')">
      <div class="todo_title">A</div><div class="todo_subjt">Course</div>
    </div>
  """;
  test(
    'normal placeholders and JS do not suppress real MISSING candidates',
    () async {
      await seed('a');
      await seed('b');
      final html = '''$valid
      <div class="todo_wrap no_data" id="no_data" style="display:none"></div>
      <div class="pagination" data-next-page=""></div>
      <!-- <div> -->
      <script>const template = '<div>';</script>
    ''';
      final service = DefaultEcampusSyncService(
        todoService: DefaultEcampusTodoService(
          client: _HtmlClient(html),
          parser: const EcampusTodoParser(),
        ),
        classifier: const EcampusSyncClassifier(),
      );
      final result = await service.previewSync(
        session: EcampusSession(cookies: const {}, createdAt: _now),
        existingTasks: await tasks.getTasks(
          origin: TaskOrigin.ecampus,
          includeArchived: true,
        ),
      );
      expect(result.missingItems.single.existingTask!.id, 'b');
      expect(result.errorItems, isEmpty);
      expect((await tasks.getTaskById('b'))!.status, TaskStatus.active);
    },
  );
  for (final (label, html) in [
    (
      'malformed item',
      '$valid<div class="todo_wrap"><div class="todo_title">B</div></div>',
    ),
    ('truncated item', '$valid<div class="todo_wrap"'),
    ('repaired unclosed container', '<div>$valid'),
    (
      'paginated',
      '<div class="pagination"><a href="?page=2" rel="next">Next</a></div>$valid',
    ),
    ('unrecognized HTML', '<html><body>Unexpected</body></html>'),
  ]) {
    test(
      '$label suppresses MISSING while leaving existing tasks unchanged',
      () async {
        await seed('a');
        await seed('b');
        final service = DefaultEcampusSyncService(
          todoService: DefaultEcampusTodoService(
            client: _HtmlClient(html),
            parser: const EcampusTodoParser(),
          ),
          classifier: const EcampusSyncClassifier(),
        );
        final result = await service.previewSync(
          session: EcampusSession(cookies: const {}, createdAt: _now),
          existingTasks: await tasks.getTasks(
            origin: TaskOrigin.ecampus,
            includeArchived: true,
          ),
        );
        expect(result.missingItems, isEmpty);
        expect(result.errorItems, isNotEmpty);
        expect(
          (await tasks.getTasks()).every((t) => t.status == TaskStatus.active),
          isTrue,
        );
        expect(await database.select(database.importSessions).get(), isEmpty);
      },
    );
  }
}

class _HtmlClient implements EcampusTodoClient {
  const _HtmlClient(this.html);
  final String html;
  @override
  Future<String> fetchTodoHtml(EcampusSession session) async => html;
}

class _Notifications extends LocalNotificationService {
  final scheduled = <Task>[];
  final cancelled = <String>[];
  bool fail = false;
  Future<void> Function(Task)? onSchedule;
  @override
  Future<void> scheduleTaskNotification({
    required Task task,
    required NotificationSetting setting,
    bool requestPermissionBeforeScheduling = false,
  }) async {
    scheduled.add(task);
    await onSchedule?.call(task);
    if (fail) throw StateError('fixture OS failure');
  }

  @override
  Future<void> cancelTaskNotification(String taskId) async =>
      cancelled.add(taskId);
}
