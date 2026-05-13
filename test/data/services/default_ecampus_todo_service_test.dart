import 'package:flutter_test/flutter_test.dart';
import 'package:ku_task_management/data/services/default_ecampus_todo_service.dart';
import 'package:ku_task_management/data/services/ecampus_auth_service.dart';
import 'package:ku_task_management/data/services/ecampus_todo_client.dart';
import 'package:ku_task_management/data/services/ecampus_todo_parser.dart';

void main() {
  final session = EcampusSession(
    cookies: const {'JSESSIONID': 'session-id'},
    createdAt: DateTime(2026, 5, 5, 10),
  );

  group('DefaultEcampusTodoService', () {
    test('fetchTodoHtml delegates to client', () async {
      const html = '<div class="todo_wrap no_data" id="no_data"></div>';
      final client = _FakeEcampusTodoClient(html);
      final service = DefaultEcampusTodoService(
        client: client,
        parser: const EcampusTodoParser(),
      );

      final fetched = await service.fetchTodoHtml(session);

      expect(fetched, html);
      expect(client.lastSession, same(session));
    });

    test('parseTodoHtml delegates to parser', () {
      final service = DefaultEcampusTodoService(
        client: _FakeEcampusTodoClient(''),
        parser: const EcampusTodoParser(),
      );

      final result = service.parseTodoHtml(_todoHtml);

      expect(result.failures, isEmpty);
      expect(result.tasks.single.sourceKey, 'A20261BBAB590693222001:13429606:project');
    });

    test('fetchAndParse fetches html and returns parse result', () async {
      final client = _FakeEcampusTodoClient(_todoHtml);
      final service = DefaultEcampusTodoService(
        client: client,
        parser: const EcampusTodoParser(),
      );

      final result = await service.fetchAndParse(session);

      expect(result.failures, isEmpty);
      expect(result.tasks.single.title, '운영체제 팀플 과제');
      expect(client.lastSession, same(session));
    });
  });
}

const _todoHtml = '''
  <div class="todo_wrap on"
      onclick="goLecture('A20261BBAB590693222001','13429606','project')">
    <input type="hidden" id="kj_0" value="A20261BBAB590693222001"/>
    <input type="hidden" id="gubun_0" value="project"/>
    <div class="todo_title">운영체제 팀플 과제</div>
    <div class="todo_subjt">운영체제</div>
    <div class="todo_date">
      <span class="todo_d_day">D-6</span>
      <span class="todo_date">5월 20일 (화)</span>
    </div>
  </div>
''';

class _FakeEcampusTodoClient implements EcampusTodoClient {
  _FakeEcampusTodoClient(this.html);

  final String html;
  EcampusSession? lastSession;

  @override
  Future<String> fetchTodoHtml(EcampusSession session) async {
    lastSession = session;
    return html;
  }
}
