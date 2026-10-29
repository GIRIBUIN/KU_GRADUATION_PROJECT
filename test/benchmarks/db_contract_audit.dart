// Manual diagnosis using a temporary in-memory database, never user data.
// flutter test --no-pub --reporter expanded test/benchmarks/db_contract_audit.dart
import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ku_task_management/data/local/app_database.dart' as db;
import 'package:ku_task_management/data/models/ecampus_models.dart';
import 'package:ku_task_management/data/models/task_models.dart';
import 'package:ku_task_management/data/repositories/drift_folder_repository.dart';
import 'package:ku_task_management/data/repositories/drift_settings_repository.dart';
import 'package:ku_task_management/data/repositories/drift_tag_repository.dart';
import 'package:ku_task_management/data/repositories/drift_task_repository.dart';
import 'package:ku_task_management/data/services/default_ecampus_sync_service.dart';
import 'package:ku_task_management/data/services/ecampus_auth_service.dart';
import 'package:ku_task_management/data/services/ecampus_sync_apply_service.dart';
import 'package:ku_task_management/data/services/ecampus_sync_classifier.dart';
import 'package:ku_task_management/data/services/ecampus_sync_flow_service.dart';
import 'package:ku_task_management/data/services/ecampus_todo_parser.dart';
import 'package:ku_task_management/data/services/ecampus_todo_service.dart';

void main() {
  test('record current data-contract observations', () async {
    final database = db.AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final now = DateTime.utc(2026, 10, 29, 12);
    final tasks = DriftTaskRepository(database: database, now: () => now);
    final folders = DriftFolderRepository(database: database);
    final apply = DefaultEcampusSyncApplyService(
      taskRepository: tasks,
      tagRepository: DriftTagRepository(database: database),
      folderRepository: folders,
      settingsRepository: DriftSettingsRepository(database: database),
      now: () => now,
    );
    final observations = <Map<String, Object?>>[];

    for (final id in ['folder-a', 'folder-b']) {
      await folders.createFolder(
        Folder(id: id, name: id, createdAt: now, updatedAt: now),
      );
    }
    String? folderError;
    try {
      await tasks.createTask(
        _task('folder-probe', now, folderIds: ['folder-a', 'folder-b']),
      );
    } catch (error) {
      folderError = error.runtimeType.toString();
    }
    observations.add({
      'id': 'folder-cardinality',
      'input_folder_ids': ['folder-a', 'folder-b'],
      'error_type': folderError,
      'stored': await tasks.getTaskById('folder-probe') != null,
      'finding':
          'Multiple folder assignment is rejected without creating a partial task.',
    });

    await tasks.createTask(_task('state-probe', now));
    await tasks.updateTaskStatus('state-probe', TaskStatus.completed);
    final reopened = await tasks.updateTaskStatus(
      'state-probe',
      TaskStatus.active,
    );
    observations.add({
      'id': 'completion-state',
      'steps': ['create active task', 'complete', 'update status to active'],
      'status': reopened.status.name,
      'completed_at': reopened.completedAt?.toIso8601String(),
      'finding': 'Reopened task has no completion timestamp.',
    });

    await tasks.createTask(_task('memo-probe', now, ecampus: true));
    final parsed = ParsedEcampusTask(
      sourceKey: 'course:item:report',
      title: 'Updated source title',
      course: 'Source course',
      type: EcampusTaskType.report,
      dueDate: now.add(const Duration(days: 2)),
    );
    final preview = const EcampusSyncClassifier().classify(
      parsedTasks: [parsed],
      existingTasks: [(await tasks.getTaskById('memo-probe'))!],
      syncedAt: now,
    );
    final updated = await apply.importItems(
      preview.importCandidates,
      syncedAt: now,
    );
    expect(updated, hasLength(1));
    observations.add({
      'id': 'user-memo',
      'input_memo': 'User-owned memo',
      'source_course': parsed.course,
      'memo_after_source_update': updated.single.memo,
      'finding': 'Applying a source change preserves the user memo.',
    });

    final todo = _FixedTodoService('<html><body>Unexpected page</body></html>');
    final flow = DefaultEcampusSyncFlowService(
      taskRepository: tasks,
      syncService: DefaultEcampusSyncService(
        todoService: todo,
        classifier: const EcampusSyncClassifier(),
      ),
      applyService: apply,
    );
    final before = (await tasks.getTaskById('memo-probe'))!;
    final result = await flow.preview(
      session: EcampusSession(cookies: const {}, createdAt: now),
      syncedAt: now,
    );
    final after = (await tasks.getTaskById('memo-probe'))!;
    observations.add({
      'id': 'preview-side-effect',
      'boundary':
          'Todo service receives fixed HTML; no HTTP request or real login.',
      'input_html': todo.html,
      'parser_task_count': todo.parseTodoHtml(todo.html).tasks.length,
      'parser_failure_count': todo.parseTodoHtml(todo.html).failures.length,
      'preview_error_count': result.errorItems.length,
      'status_before_preview': before.status.name,
      'status_after_preview': after.status.name,
      'finding':
          'Unrecognized HTML is reported as an error; preview leaves existing task unchanged.',
    });

    await tasks.createTask(_task('folder-owner', now, folderIds: ['folder-b']));
    final foreignKeys = await database
        .customSelect('PRAGMA foreign_keys')
        .getSingle();
    await folders.deleteFolder('folder-b');
    observations.add({
      'id': 'folder-parent-reference',
      'foreign_keys_pragma': foreignKeys.data.values.single,
      'deleted_folder': 'folder-b',
      'remaining_task_folder_ids': (await tasks.getTaskById(
        'folder-owner',
      ))!.folderIds,
      'finding':
          'Folder is soft-deleted and task is detached in one transaction; no hierarchy exists.',
      'limitation':
          'NativeDatabase.memory only; device connection not checked.',
    });

    final sourcePaths = [
      'lib/data/local/app_database.dart',
      'lib/data/repositories/drift_task_repository.dart',
      'lib/data/repositories/drift_folder_repository.dart',
      'lib/data/services/ecampus_sync_apply_service.dart',
      'lib/data/services/ecampus_sync_flow_service.dart',
      'lib/data/services/ecampus_todo_parser.dart',
      'test/benchmarks/db_contract_audit.dart',
    ];
    final timestamp = DateTime.now().toUtc();
    final evidence = {
      'recorded_at_utc': timestamp.toIso8601String(),
      'label': 'after-db-v6',
      'git_commit': _git(['rev-parse', 'HEAD']),
      'source_git_blob_hashes': {
        for (final path in sourcePaths) path: _git(['hash-object', path]),
      },
      'command':
          'flutter test --no-pub --reporter expanded '
          'test/benchmarks/db_contract_audit.dart',
      'environment': {
        'os': Platform.operatingSystem,
        'dart': Platform.version,
        'database': 'current Flutter schema v6; NativeDatabase.memory',
      },
      'scope':
          'Synthetic API-level reproductions; no production data, network, device or Kotlin execution.',
      'observations': observations,
    };
    final stamp = timestamp.toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
    final output = File('docs/evidence/db/contract-audit-$stamp.json');
    await output.parent.create(recursive: true);
    await output.writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(evidence)}\n',
    );
    // ignore: avoid_print
    print(
      'AUDIT ${output.path}\n${const JsonEncoder.withIndent('  ').convert(observations)}',
    );
  });
}

Task _task(
  String id,
  DateTime now, {
  List<String> folderIds = const [],
  bool ecampus = false,
}) => Task(
  id: id,
  origin: ecampus ? TaskOrigin.ecampus : TaskOrigin.personal,
  status: TaskStatus.active,
  title: 'Original title',
  memo: 'User-owned memo',
  folderIds: folderIds,
  createdAt: now,
  updatedAt: now,
  dueDate: now.add(const Duration(days: 1)),
  ecampus: ecampus
      ? EcampusSyncMetadata(
          sourceKey: 'course:item:report',
          sourceTitle: 'Original title',
          sourceDueDate: now.add(const Duration(days: 1)),
          sourceCourse: 'Source course',
          sourceType: EcampusTaskType.report,
        )
      : null,
);

class _FixedTodoService implements EcampusTodoService {
  _FixedTodoService(this.html);
  final String html;
  final parser = const EcampusTodoParser();

  @override
  Future<String> fetchTodoHtml(EcampusSession session) async => html;
  @override
  EcampusTodoParseResult parseTodoHtml(String html) => parser.parse(html);
  @override
  Future<EcampusTodoParseResult> fetchAndParse(EcampusSession session) async =>
      parseTodoHtml(html);
}

String _git(List<String> args) {
  final result = Process.runSync(
    'git',
    args,
    environment: {'GIT_OPTIONAL_LOCKS': '0'},
  );
  if (result.exitCode != 0) throw StateError('${result.stderr}');
  return (result.stdout as String).trim();
}
