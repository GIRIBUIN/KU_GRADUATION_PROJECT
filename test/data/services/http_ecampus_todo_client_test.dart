import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ku_task_management/data/services/ecampus_auth_service.dart';
import 'package:ku_task_management/data/services/http_ecampus_todo_client.dart';

void main() {
  final session = EcampusSession(
    cookies: const {
      'JSESSIONID': 'session-id',
      '_language_': 'ko',
      'co_check': 'checked',
    },
    createdAt: DateTime(2026, 5, 6, 10),
  );

  group('HttpEcampusTodoClient', () {
    test('posts to todo endpoint with session cookies and STYPE', () async {
      late http.Request capturedRequest;
      final httpClient = MockClient((request) async {
        capturedRequest = request;
        return http.Response(_todoHtml, 200);
      });
      final client = HttpEcampusTodoClient(
        httpClient: httpClient,
        baseUrl: 'https://ecampus.example.test',
      );

      final html = await client.fetchTodoHtml(session);

      expect(html, _todoHtml);
      expect(capturedRequest.method, 'POST');
      expect(
        capturedRequest.url.toString(),
        'https://ecampus.example.test/ilos/mp/todo_list.acl',
      );
      expect(
        capturedRequest.headers['Cookie'],
        contains('JSESSIONID=session-id'),
      );
      expect(capturedRequest.headers['Cookie'], contains('_language_=ko'));
      expect(
        capturedRequest.headers['Content-Type'],
        contains('application/x-www-form-urlencoded'),
      );
      expect(capturedRequest.bodyFields, {'STYPE': '1'});
    });

    test('returns todo html when response is successful', () async {
      final client = HttpEcampusTodoClient(
        httpClient: MockClient((request) async {
          return http.Response(_todoHtml, 200);
        }),
      );

      final html = await client.fetchTodoHtml(session);

      expect(html, _todoHtml);
    });

    test('throws fetch exception when response is not successful', () async {
      final client = HttpEcampusTodoClient(
        httpClient: MockClient((request) async {
          return http.Response('server error', 500);
        }),
      );

      expect(
        () => client.fetchTodoHtml(session),
        throwsA(isA<EcampusTodoFetchException>()),
      );
    });

    test(
      'throws session expired exception when login page is returned',
      () async {
        final client = HttpEcampusTodoClient(
          httpClient: MockClient((request) async {
            return http.Response(_loginHtml, 200);
          }),
        );

        expect(
          () => client.fetchTodoHtml(session),
          throwsA(isA<EcampusSessionExpiredException>()),
        );
      },
    );
  });
}

const _todoHtml = '''
  <div class="todo_wrap no_data" id="no_data"></div>
''';

const _loginHtml = '''
  <li class="header_login">
    <a href="/ilos/main/member/login_form.acl">login</a>
  </li>
''';
