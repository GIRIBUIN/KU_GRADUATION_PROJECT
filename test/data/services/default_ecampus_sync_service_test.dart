import 'package:flutter_test/flutter_test.dart';
import 'package:ku_task_management/data/models/ecampus_models.dart';
import 'package:ku_task_management/data/models/task_models.dart';
import 'package:ku_task_management/data/services/default_ecampus_sync_service.dart';
import 'package:ku_task_management/data/services/ecampus_auth_service.dart';
import 'package:ku_task_management/data/services/ecampus_sync_classifier.dart';
import 'package:ku_task_management/data/services/ecampus_todo_service.dart';

void main() {
  final session = EcampusSession(
    cookies: const {'JSESSIONID': 'session-id'},
    createdAt: DateTime(2026, 5, 7, 10),
  );
  final syncedAt = DateTime(2026, 5, 7, 11);

  group('DefaultEcampusSyncService', () {
    test('fetches, parses, and classifies parsed todo tasks', () async {
      final service = DefaultEcampusSyncService(
        todoService: _FakeEcampusTodoService(
          parseResult: EcampusTodoParseResult(
            tasks: [
              _parsedTask(sourceKey: 'new'),
              _parsedTask(sourceKey: 'same'),
              _parsedTask(sourceKey: 'changed', title: '변경된 과제'),
            ],
            failures: const [],
          ),
        ),
        classifier: const EcampusSyncClassifier(),
      );

      final result = await service.previewSync(
        session: session,
        existingTasks: [
          _task(sourceKey: 'same'),
          _task(sourceKey: 'changed', sourceTitle: '기존 과제'),
        ],
        syncedAt: syncedAt,
      );

      expect(result.syncedAt, syncedAt);
      expect(result.items.map((item) => item.kind), [
        SyncItemKind.newItem,
        SyncItemKind.alreadyImported,
        SyncItemKind.updateCandidate,
      ]);
    });

    test('adds parser failures as error sync items', () async {
      final service = DefaultEcampusSyncService(
        todoService: _FakeEcampusTodoService(
          parseResult: EcampusTodoParseResult(
            tasks: [_parsedTask(sourceKey: 'new')],
            failures: const [
              EcampusParseFailure(reason: 'missing goLecture arguments'),
            ],
          ),
        ),
        classifier: const EcampusSyncClassifier(),
      );

      final result = await service.previewSync(
        session: session,
        existingTasks: const [],
        syncedAt: syncedAt,
      );

      expect(result.items.first.kind, SyncItemKind.newItem);
      expect(
        result.errorItems.single.errorMessage,
        'missing goLecture arguments',
      );
    });

    test('propagates todo fetch errors', () {
      final service = DefaultEcampusSyncService(
        todoService: _FailingEcampusTodoService(),
        classifier: const EcampusSyncClassifier(),
      );

      expect(
        () => service.previewSync(
          session: session,
          existingTasks: const [],
          syncedAt: syncedAt,
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}

ParsedEcampusTask _parsedTask({
  required String sourceKey,
  String title = '자료구조 과제',
  String course = '자료구조',
  EcampusTaskType type = EcampusTaskType.report,
}) {
  return ParsedEcampusTask(
    sourceKey: sourceKey,
    title: title,
    course: course,
    type: type,
  );
}

Task _task({required String sourceKey, String sourceTitle = '자료구조 과제'}) {
  final now = DateTime(2026, 5, 7, 9);

  return Task(
    id: 'task-$sourceKey',
    origin: TaskOrigin.ecampus,
    status: TaskStatus.active,
    title: sourceTitle,
    createdAt: now,
    updatedAt: now,
    ecampus: EcampusSyncMetadata(
      sourceKey: sourceKey,
      sourceTitle: sourceTitle,
      sourceCourse: '자료구조',
      sourceType: EcampusTaskType.report,
    ),
  );
}

class _FakeEcampusTodoService implements EcampusTodoService {
  const _FakeEcampusTodoService({required this.parseResult});

  final EcampusTodoParseResult parseResult;

  @override
  Future<String> fetchTodoHtml(EcampusSession session) async {
    return '<html></html>';
  }

  @override
  EcampusTodoParseResult parseTodoHtml(String html) {
    return parseResult;
  }

  @override
  Future<EcampusTodoParseResult> fetchAndParse(EcampusSession session) async {
    return parseResult;
  }
}

class _FailingEcampusTodoService implements EcampusTodoService {
  @override
  Future<String> fetchTodoHtml(EcampusSession session) {
    throw StateError('fetch failed');
  }

  @override
  EcampusTodoParseResult parseTodoHtml(String html) {
    throw StateError('parse should not be called');
  }

  @override
  Future<EcampusTodoParseResult> fetchAndParse(EcampusSession session) {
    throw StateError('fetch failed');
  }
}
