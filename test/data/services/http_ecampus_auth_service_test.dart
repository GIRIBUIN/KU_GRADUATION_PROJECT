import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ku_task_management/data/services/ecampus_auth_service.dart';
import 'package:ku_task_management/data/services/http_ecampus_auth_service.dart';

void main() {
  final session = EcampusSession(
    cookies: const {'JSESSIONID': 'session-id', '_language_': 'ko'},
    createdAt: DateTime(2026, 5, 7, 10),
  );

  group('EcampusSession', () {
    test('reports session cookie state', () {
      expect(session.hasSessionCookie, isTrue);
      expect(session.isEmpty, isFalse);

      final emptySession = EcampusSession(
        cookies: const {'SCOUTER': 'scouter-id'},
        createdAt: DateTime(2026, 5, 7, 10),
      );

      expect(emptySession.hasSessionCookie, isFalse);
      expect(emptySession.isEmpty, isTrue);
    });

    test('reports whether session is older than a duration', () {
      expect(
        session.isOlderThan(const Duration(hours: 2), DateTime(2026, 5, 7, 13)),
        isTrue,
      );
      expect(
        session.isOlderThan(const Duration(hours: 4), DateTime(2026, 5, 7, 13)),
        isFalse,
      );
    });
  });

  group('HttpEcampusAuthService', () {
    test(
      'sends logout request with session cookies and clears cookies',
      () async {
        late http.Request capturedRequest;
        final cookieStore = _FakeEcampusCookieStore();
        final service = HttpEcampusAuthService(
          httpClient: MockClient((request) async {
            capturedRequest = request;
            return http.Response('', 200);
          }),
          cookieStore: cookieStore,
          baseUrl: 'https://ecampus.example.test',
        );

        await service.logout(session);

        expect(capturedRequest.method, 'GET');
        expect(
          capturedRequest.url.toString(),
          'https://ecampus.example.test/ilos/lo/logout.acl',
        );
        expect(
          capturedRequest.headers['Cookie'],
          contains('JSESSIONID=session-id'),
        );
        expect(cookieStore.clearCount, 1);
      },
    );

    test('throws logout exception when response is not successful', () async {
      final service = HttpEcampusAuthService(
        httpClient: MockClient((request) async {
          return http.Response('server error', 500);
        }),
      );

      expect(
        () => service.logout(session),
        throwsA(isA<EcampusLogoutException>()),
      );
    });

    test(
      'clears session without logout request when session is empty',
      () async {
        var requestCount = 0;
        final cookieStore = _FakeEcampusCookieStore();
        final service = HttpEcampusAuthService(
          httpClient: MockClient((request) async {
            requestCount += 1;
            return http.Response('', 200);
          }),
          cookieStore: cookieStore,
        );
        final emptySession = EcampusSession(
          cookies: const {},
          createdAt: DateTime(2026, 5, 7, 10),
        );

        await service.logout(emptySession);

        expect(requestCount, 0);
        expect(cookieStore.clearCount, 1);
      },
    );
  });
}

class _FakeEcampusCookieStore implements EcampusCookieStore {
  var clearCount = 0;

  @override
  Future<void> clearEcampusCookies() async {
    clearCount += 1;
  }
}
