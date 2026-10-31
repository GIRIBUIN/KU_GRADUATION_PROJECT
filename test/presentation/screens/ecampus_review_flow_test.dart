import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ku_task_management/core/utils/list_defaults.dart';
import 'package:ku_task_management/data/local/app_database.dart' as db;
import 'package:ku_task_management/data/models/ecampus_models.dart';
import 'package:ku_task_management/data/models/task_models.dart';
import 'package:ku_task_management/data/repositories/drift_folder_repository.dart';
import 'package:ku_task_management/data/repositories/drift_notification_repository.dart';
import 'package:ku_task_management/data/repositories/drift_settings_repository.dart';
import 'package:ku_task_management/data/repositories/drift_tag_repository.dart';
import 'package:ku_task_management/data/repositories/drift_task_repository.dart';
import 'package:ku_task_management/data/services/ecampus_auth_service.dart';
import 'package:ku_task_management/data/services/ecampus_sync_apply_service.dart';
import 'package:ku_task_management/data/services/ecampus_sync_flow_service.dart';
import 'package:ku_task_management/data/services/ecampus_sync_service.dart';
import 'package:ku_task_management/data/services/http_ecampus_auth_service.dart';
import 'package:ku_task_management/presentation/screens/sync/ecampus_sync_preview_screen.dart';
import 'package:ku_task_management/presentation/screens/sync/ecampus_sync_progress_screen.dart';
import 'package:ku_task_management/presentation/services/local_notification_service.dart';

void main() {
  late db.AppDatabase database;
  late DriftTaskRepository tasks;
  late DriftTagRepository tags;
  late DriftFolderRepository folders;
  late DriftSettingsRepository settings;
  late DriftNotificationRepository reminders;

  setUp(() {
    database = db.AppDatabase(NativeDatabase.memory());
    tasks = DriftTaskRepository(database: database);
    tags = DriftTagRepository(database: database);
    folders = DriftFolderRepository(database: database);
    settings = DriftSettingsRepository(database: database);
    reminders = DriftNotificationRepository(database: database);
  });
  tearDown(() => database.close());

  DefaultEcampusSyncFlowService flow([_ResultService? source]) =>
      DefaultEcampusSyncFlowService(
        taskRepository: tasks,
        syncService: source ?? _ResultService(),
        applyService: DefaultEcampusSyncApplyService(
          taskRepository: tasks,
          tagRepository: tags,
          folderRepository: folders,
          settingsRepository: settings,
        ),
      );

  Future<Task> seed() => tasks.createTask(
    Task(
      id: 'task',
      origin: TaskOrigin.ecampus,
      status: TaskStatus.active,
      title: 'My title',
      memo: 'My memo',
      dueDate: DateTime(2027, 1, 1),
      createdAt: DateTime(2026, 10, 30),
      updatedAt: DateTime(2026, 10, 30),
      ecampus: const EcampusSyncMetadata(
        sourceKey: 'c:1:report',
        sourceTitle: 'Old source',
      ),
    ),
  );

  Future<void> largeScreen(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets(
    'CHANGED keeps current values and cannot be mistaken for NEW exclusion',
    (tester) async {
      await largeScreen(tester);
      final old = await seed();
      await tester.pumpWidget(
        MaterialApp(
          home: EcampusSyncPreviewScreen(
            syncFlowService: flow(),
            syncResult: SyncResult(
              syncedAt: DateTime.now(),
              items: [
                SyncItem(
                  kind: SyncItemKind.updateCandidate,
                  existingTask: old,
                  parsedTask: ParsedEcampusTask(
                    sourceKey: 'c:1:report',
                    title: 'New source',
                    course: 'Course',
                    type: EcampusTaskType.report,
                    dueDate: DateTime(2027, 2, 1),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final exclude = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, '신규 선택 제외'),
      );
      expect(exclude.onPressed, isNull);
      expect(
        tester
            .widget<CheckboxListTile>(
              find.widgetWithText(CheckboxListTile, '원본 제목으로 변경'),
            )
            .value,
        isFalse,
      );
      expect(
        tester
            .widget<CheckboxListTile>(
              find.widgetWithText(CheckboxListTile, '원본 마감일로 변경'),
            )
            .value,
        isFalse,
      );
      await tester.tap(find.text('선택 반영 (1)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();
      final saved = (await tasks.getTaskById('task'))!;
      expect(saved.title, old.title);
      expect(saved.dueDate, old.dueDate);
      expect(saved.memo, old.memo);
      expect(saved.ecampus!.sourceTitle, 'New source');
      expect(
        (await database.select(database.ecampusItems).get()).single.importState,
        'imported',
      );
      await tester.ensureVisible(find.text('현재 값 유지'));
      expect(find.text('현재 값 유지'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final archived in [false, true]) {
    testWidgets(
      'already imported task exposes its actual saved list and task ID (archived=$archived)',
      (tester) async {
        await largeScreen(tester);
        final at = DateTime.now();
        if (archived) {
          await folders.createFolder(
            Folder(
              id: 'archived',
              name: 'Old course',
              createdAt: at,
              updatedAt: at,
            ),
          );
        }
        final saved = await tasks.createTask(
          Task(
            id: 'existing',
            title: 'Saved task',
            origin: TaskOrigin.ecampus,
            status: TaskStatus.active,
            folderIds: [archived ? 'archived' : inboxListId],
            createdAt: at,
            updatedAt: at,
            ecampus: const EcampusSyncMetadata(
              sourceKey: 'course:existing:report',
              sourceTitle: 'Saved task',
            ),
          ),
        );
        if (archived) await folders.deleteFolder('archived');
        Task? opened;
        await tester.pumpWidget(
          MaterialApp(
            home: EcampusSyncPreviewScreen(
              syncResult: SyncResult(
                items: [
                  SyncItem(
                    kind: SyncItemKind.alreadyImported,
                    existingTask: saved,
                  ),
                ],
                syncedAt: at,
              ),
              syncFlowService: flow(),
              folderRepository: folders,
              onOpenTask: (task) async => opened = task,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(archived ? '현재 목록: Old course (보관됨)' : '현재 목록: 미지정'),
          findsOneWidget,
        );
        await tester.ensureVisible(find.text('할 일 보기'));
        await tester.tap(find.text('할 일 보기'));
        await tester.pumpAndSettle();
        expect(opened?.id, saved.id);
        expect((await tasks.getTaskById(saved.id))!.listId, saved.listId);
        expect((await tasks.getTasks()).length, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'newly imported task reveals its generated course list without another import',
    (tester) async {
      await largeScreen(tester);
      final at = DateTime.now();
      Task? opened;
      await tester.pumpWidget(
        MaterialApp(
          home: EcampusSyncPreviewScreen(
            syncResult: SyncResult(
              items: [
                SyncItem(
                  kind: SyncItemKind.newItem,
                  parsedTask: ParsedEcampusTask(
                    sourceKey: 'new-course:item:report',
                    title: 'Imported task',
                    course: 'New course',
                    type: EcampusTaskType.report,
                    dueDate: at.add(const Duration(days: 40)),
                  ),
                ),
              ],
              syncedAt: at,
            ),
            syncFlowService: flow(),
            folderRepository: folders,
            onOpenTask: (task) async => opened = task,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('선택 반영 (1)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('할 일 보기'));
      expect(find.text('현재 목록: New course'), findsOneWidget);
      await tester.tap(find.text('할 일 보기'));
      await tester.pumpAndSettle();
      final saved = (await tasks.getTasks()).single;
      expect(opened?.id, saved.id);
      expect(saved.listId, isNot(inboxListId));
      expect((await folders.getFolderById(saved.listId))!.name, 'New course');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'review can organize existing unassigned imports without moving completed tasks or duplicating rows',
    (tester) async {
      await largeScreen(tester);
      final at = DateTime.now();
      final active = await tasks.createTask(
        Task(
          id: 'active',
          title: 'Active source',
          origin: TaskOrigin.ecampus,
          status: TaskStatus.active,
          folderIds: [inboxListId],
          createdAt: at,
          updatedAt: at,
          ecampus: const EcampusSyncMetadata(
            sourceKey: 'c:1:report',
            sourceTitle: 'Active source',
            sourceCourse: 'Course',
          ),
        ),
      );
      await tasks.createTask(
        Task(
          id: 'done',
          title: 'Completed source',
          origin: TaskOrigin.ecampus,
          status: TaskStatus.active,
          folderIds: [inboxListId],
          createdAt: at,
          updatedAt: at,
          ecampus: const EcampusSyncMetadata(
            sourceKey: 'c:2:report',
            sourceTitle: 'Completed source',
            sourceCourse: 'Course',
          ),
        ),
      );
      final done = await tasks.updateTaskStatus('done', TaskStatus.completed);
      await tester.pumpWidget(
        MaterialApp(
          home: EcampusSyncPreviewScreen(
            folderRepository: folders,
            syncFlowService: flow(),
            onOrganizeUnassigned: tasks.organizeUnassignedEcampusTasks,
            syncResult: SyncResult(
              items: [
                SyncItem(
                  kind: SyncItemKind.alreadyImported,
                  existingTask: active,
                ),
                SyncItem(kind: SyncItemKind.completed, existingTask: done),
              ],
              syncedAt: at,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('미지정 1개 과목별 정리'));
      await tester.tap(find.text('미지정 1개 과목별 정리'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '정리'));
      await tester.pumpAndSettle();
      expect((await tasks.getTaskById('active'))!.listId, isNot(inboxListId));
      expect((await tasks.getTaskById('done'))!.listId, inboxListId);
      expect(find.text('현재 목록: Course'), findsOneWidget);
      expect(find.text('Active source'), findsOneWidget);
      expect(find.text('Completed source'), findsOneWidget);
      expect(find.text('미지정 1개 과목별 정리'), findsNothing);
      expect((await tasks.getTasks(includeArchived: true)).length, 2);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('NEW exclusion stores only an ignored source', (tester) async {
    await largeScreen(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: EcampusSyncPreviewScreen(
          syncFlowService: flow(),
          syncResult: SyncResult(
            syncedAt: DateTime.now(),
            items: const [
              SyncItem(
                kind: SyncItemKind.newItem,
                parsedTask: ParsedEcampusTask(
                  sourceKey: 'c:1:report',
                  title: 'New source',
                  course: 'Course',
                  type: EcampusTaskType.report,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('신규 선택 제외'));
    await tester.pumpAndSettle();
    expect(await database.select(database.tasks).get(), isEmpty);
    expect(
      (await database.select(database.ecampusItems).get()).single.importState,
      'ignored',
    );
    expect(find.text('다시 가져오기'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'NEW can explicitly target Inbox instead of automatic course placement',
    (tester) async {
      await largeScreen(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: EcampusSyncPreviewScreen(
            syncFlowService: flow(),
            folderRepository: folders,
            syncResult: SyncResult(
              syncedAt: DateTime.now(),
              items: const [
                SyncItem(
                  kind: SyncItemKind.newItem,
                  parsedTask: ParsedEcampusTask(
                    sourceKey: 'c:1:report',
                    title: 'New source',
                    course: 'Course',
                    type: EcampusTaskType.report,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('자동: 과목별 목록'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('미지정').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('선택 반영 (1)'));
      await tester.pumpAndSettle();
      expect((await tasks.getTasks()).single.listId, 'kutodo:inbox');
      expect(await folders.getGroups(), isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  for (final decision in MissingItemDecision.values) {
    testWidgets(
      'MISSING review defaults to KEEP and explicitly applies $decision',
      (tester) async {
        await largeScreen(tester);
        if (decision == MissingItemDecision.keep) {
          await tester.binding.setSurfaceSize(const Size(360, 800));
        }
        final old = await seed();
        await tester.pumpWidget(
          MaterialApp(
            home: EcampusSyncPreviewScreen(
              syncFlowService: flow(),
              syncResult: SyncResult(
                syncedAt: DateTime.now(),
                items: [
                  SyncItem(kind: SyncItemKind.missing, existingTask: old),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final dropdown = find.byKey(const ValueKey('missing-task'));
        await tester.ensureVisible(dropdown);
        expect(
          tester.widget<DropdownButton<MissingItemDecision>>(dropdown).value,
          MissingItemDecision.keep,
        );
        if (decision != MissingItemDecision.keep) {
          await tester.tap(dropdown);
          await tester.pumpAndSettle();
          await tester.tap(
            find
                .text(
                  decision == MissingItemDecision.complete ? '완료' : '삭제 (휴지통)',
                )
                .last,
          );
          await tester.pumpAndSettle();
        }
        await tester.ensureVisible(find.text('누락 검토 반영'));
        await tester.tap(find.text('누락 검토 반영'));
        await tester.pumpAndSettle();
        final saved = (await tasks.getTaskById('task'))!;
        expect(saved.status, switch (decision) {
          MissingItemDecision.keep => TaskStatus.active,
          MissingItemDecision.complete => TaskStatus.completed,
          MissingItemDecision.delete => TaskStatus.deleted,
        });
        expect(find.byKey(const ValueKey('missing-task')), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final scenario in [
    'success',
    'cancel',
    'retry',
    'back during fetch',
    'late login after cancel',
  ]) {
    testWidgets(
      'inline login removes the extra route and preserves cleanup: $scenario',
      (tester) async {
        await largeScreen(tester);
        final routes = _Routes();
        final cookies = _Cookies();
        final changes = <EcampusSession?>[];
        var loginRequests = 0;
        var logoutRequests = 0;
        ValueChanged<EcampusSession>? completeLogin;
        final client = MockClient((_) async {
          logoutRequests++;
          return http.Response('', 200);
        });
        addTearDown(client.close);
        final auth = HttpEcampusAuthService(
          httpClient: client,
          cookieStore: cookies,
        );
        final results = _ResultService()
          ..fail = scenario == 'retry'
          ..pending = scenario == 'success' || scenario == 'back during fetch'
              ? Completer<SyncResult>()
              : null;
        await tester.pumpWidget(
          MaterialApp(
            navigatorObservers: [routes],
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  child: const Text('Open'),
                  onPressed: () => Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => EcampusSyncProgressScreen(
                        taskRepository: tasks,
                        tagRepository: tags,
                        folderRepository: folders,
                        settingsRepository: settings,
                        notificationRepository: reminders,
                        localNotificationService: _NoNotifications(),
                        authService: auth,
                        syncFlowService: flow(results),
                        onSessionChanged: changes.add,
                        loginBuilder: (context, onLoggedIn) {
                          completeLogin = onLoggedIn;
                          return Scaffold(
                            appBar: AppBar(title: const Text('eCampus 로그인')),
                            body: FilledButton(
                              child: const Text('Fixture login'),
                              onPressed: () {
                                loginRequests++;
                                cookies.hasCookies = true;
                                final session = EcampusSession(
                                  cookies: const {'JSESSIONID': 'fixture'},
                                  createdAt: DateTime.now(),
                                );
                                onLoggedIn(session);
                                onLoggedIn(session);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(find.text('eCampus 로그인'), findsOneWidget);
        expect(find.text('동기화 상태'), findsNothing);
        expect(routes.pushed, hasLength(2));
        if (scenario == 'cancel' || scenario == 'late login after cancel') {
          cookies.hasCookies = true;
          await tester.pageBack();
          await tester.pumpAndSettle();
          if (scenario == 'late login after cancel') {
            cookies.hasCookies = true;
            final late = EcampusSession(
              cookies: const {'JSESSIONID': 'late-fixture'},
              createdAt: DateTime.now(),
            );
            completeLogin!(late);
            completeLogin!(late);
            await tester.pumpAndSettle();
          }
          expect(loginRequests, 0);
          expect(results.requests, 0);
        } else {
          await tester.tap(find.text('Fixture login'));
          if (results.pending != null) {
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 400));
            expect(find.text('일정을 가져오는 중입니다.'), findsOneWidget);
            expect(routes.pushed, hasLength(2));
            if (scenario == 'back during fetch') {
              await tester.pageBack();
              await tester.pump(const Duration(milliseconds: 400));
            }
            results.pending!.complete(
              SyncResult(items: const [], syncedAt: DateTime.now()),
            );
          }
          await tester.pumpAndSettle();
          if (scenario == 'retry') {
            expect(find.text('eCampus 가져오기에 실패했습니다.'), findsOneWidget);
            expect(cookies.hasCookies, isFalse);
            expect(changes.last, isNull);
            expect(logoutRequests, 1);
            results.fail = false;
            await tester.tap(find.text('다시 시도'));
            await tester.pumpAndSettle();
            expect(find.text('eCampus 로그인'), findsOneWidget);
            expect(routes.pushed, hasLength(2));
            await tester.tap(find.text('Fixture login'));
            await tester.pumpAndSettle();
          }
          if (scenario != 'back during fetch') {
            expect(find.byType(EcampusSyncPreviewScreen), findsOneWidget);
            expect(routes.pushed, hasLength(3));
            await tester.tap(find.text('닫기'));
            await tester.pumpAndSettle();
          }
          expect(loginRequests, scenario == 'retry' ? 2 : 1);
          expect(results.requests, loginRequests);
        }
        expect(find.byType(EcampusSyncProgressScreen), findsNothing);
        expect(find.text('Open'), findsOneWidget);
        expect(cookies.hasCookies, isFalse);
        expect(cookies.clears, greaterThanOrEqualTo(2));
        expect(changes.last, isNull);
        expect(
          logoutRequests,
          scenario == 'cancel'
              ? 0
              : scenario == 'retry'
              ? 2
              : 1,
        );
        expect(
          routes.pushed,
          hasLength(
            scenario == 'cancel' ||
                    scenario == 'late login after cancel' ||
                    scenario == 'back during fetch'
                ? 2
                : 3,
          ),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final scenario in [
    'success',
    'cancel login',
    'fetch failure',
    'logout failure',
    'back during fetch',
    'commit success',
    'commit failure',
  ]) {
    testWidgets('session lifecycle cleans memory and cookies: $scenario', (
      tester,
    ) async {
      await largeScreen(tester);
      final cookies = _Cookies();
      var logoutRequests = 0;
      var loginRequests = 0;
      final changes = <EcampusSession?>[];
      final client = MockClient((_) async {
        logoutRequests++;
        return http.Response('', scenario == 'logout failure' ? 500 : 200);
      });
      addTearDown(client.close);
      final auth = HttpEcampusAuthService(
        httpClient: client,
        cookieStore: cookies,
      );
      final results = _ResultService()
        ..fail = scenario == 'fetch failure'
        ..pending = scenario == 'back during fetch'
            ? Completer<SyncResult>()
            : null;
      if (scenario.startsWith('commit')) {
        results.items = const [
          SyncItem(
            kind: SyncItemKind.newItem,
            parsedTask: ParsedEcampusTask(
              sourceKey: 'c:1:report',
              title: 'Imported',
              course: 'Course',
              type: EcampusTaskType.report,
            ),
          ),
        ];
        if (scenario == 'commit failure') {
          await database.customStatement("""
            CREATE TRIGGER reject_import BEFORE INSERT ON tasks
            BEGIN SELECT RAISE(ABORT, 'fixture failure'); END;
          """);
        }
      }
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => EcampusSyncProgressScreen(
                      taskRepository: tasks,
                      tagRepository: tags,
                      folderRepository: folders,
                      settingsRepository: settings,
                      notificationRepository: reminders,
                      localNotificationService: _NoNotifications(),
                      authService: auth,
                      syncFlowService: flow(results),
                      onSessionChanged: changes.add,
                      openLogin: (_) async {
                        loginRequests++;
                        if (scenario == 'cancel login') return null;
                        cookies.hasCookies = true;
                        return EcampusSession(
                          cookies: const {'JSESSIONID': 'fixture'},
                          createdAt: DateTime.now(),
                        );
                      },
                    ),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      if (scenario == 'back during fetch') {
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pageBack();
        await tester.pump(const Duration(milliseconds: 400));
        results.pending!.complete(
          SyncResult(items: const [], syncedAt: DateTime.now()),
        );
        await tester.pumpAndSettle();
      } else {
        await tester.pumpAndSettle();
        if (scenario.startsWith('commit')) {
          await tester.tap(find.text('선택 반영 (1)'));
          await tester.pumpAndSettle();
          // Credentials are already gone before dismissing the result dialog
          // or leaving a failed apply's preview.
          expect(cookies.hasCookies, isFalse);
          expect(changes.last, isNull);
          expect(logoutRequests, 1);
          if (scenario == 'commit success') {
            expect(await database.select(database.tasks).get(), hasLength(1));
            await tester.tap(find.text('확인'));
            await tester.pumpAndSettle();
          } else {
            expect(await database.select(database.tasks).get(), isEmpty);
            expect(find.textContaining('가져오기에 실패했습니다'), findsOneWidget);
          }
          await tester.tap(find.text('닫기'));
          await tester.pumpAndSettle();
        }
        if (scenario == 'success' || scenario == 'logout failure') {
          expect(find.text('동기화 미리보기'), findsOneWidget);
          await tester.tap(find.text('닫기'));
          await tester.pumpAndSettle();
        }
      }
      expect(changes, isNotEmpty);
      expect(changes.last, isNull);
      expect(cookies.hasCookies, isFalse);
      expect(cookies.clears, greaterThanOrEqualTo(2));
      expect(logoutRequests, scenario == 'cancel login' ? 0 : 1);
      if (scenario == 'success') {
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(loginRequests, 2);
        await tester.tap(find.text('닫기'));
        await tester.pumpAndSettle();
        expect(logoutRequests, 2);
        expect(changes.last, isNull);
      }
      expect(tester.takeException(), isNull);
    });
  }
}

class _NoNotifications extends LocalNotificationService {}

class _Cookies implements EcampusCookieStore {
  bool hasCookies = false;
  int clears = 0;
  @override
  Future<void> clearEcampusCookies() async {
    hasCookies = false;
    clears++;
  }
}

class _ResultService implements EcampusSyncService {
  bool fail = false;
  int requests = 0;
  List<SyncItem> items = const [];
  Completer<SyncResult>? pending;
  @override
  Future<SyncResult> previewSync({
    required EcampusSession session,
    required List<Task> existingTasks,
    DateTime? syncedAt,
  }) async {
    requests++;
    if (fail) throw StateError('fixture fetch failure');
    if (pending != null) return pending!.future;
    return SyncResult(items: items, syncedAt: syncedAt ?? DateTime.now());
  }
}

class _Routes extends NavigatorObserver {
  final pushed = <Route<dynamic>>[];
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushed.add(route);
    super.didPush(route, previousRoute);
  }
}
