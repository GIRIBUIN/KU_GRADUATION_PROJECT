import 'package:http/http.dart' as http;

import 'ecampus_auth_service.dart';

class EcampusLogoutException implements Exception {
  const EcampusLogoutException(this.message);

  final String message;

  @override
  String toString() => 'EcampusLogoutException: $message';
}

class HttpEcampusAuthService implements EcampusAuthService {
  const HttpEcampusAuthService({
    required this.httpClient,
    this.cookieStore,
    this.baseUrl = 'https://ecampus.konkuk.ac.kr',
  });

  final http.Client httpClient;
  final EcampusCookieStore? cookieStore;
  final String baseUrl;

  @override
  Future<void> logout(EcampusSession session) async {
    if (session.isEmpty) {
      await clearSession();
      return;
    }

    final response = await httpClient.get(
      Uri.parse('$baseUrl/ilos/lo/logout.acl'),
      headers: {'Cookie': session.cookieHeader},
    );

    if (response.statusCode < 200 || response.statusCode >= 400) {
      throw EcampusLogoutException(
        'failed to logout from e-campus: ${response.statusCode}',
      );
    }

    await clearSession();
  }

  @override
  Future<void> clearSession() async {
    await cookieStore?.clearEcampusCookies();
  }
}
