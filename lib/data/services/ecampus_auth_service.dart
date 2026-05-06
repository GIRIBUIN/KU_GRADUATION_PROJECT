class EcampusSession {
  const EcampusSession({
    required this.cookies,
    required this.createdAt,
    this.lastUrl,
  });

  final Map<String, String> cookies;
  final DateTime createdAt;
  final String? lastUrl;

  String get cookieHeader {
    return cookies.entries
        .where((entry) => entry.key.trim().isNotEmpty)
        .map((entry) => '${entry.key}=${entry.value}')
        .join('; ');
  }
}

abstract class EcampusAuthService {
  Future<EcampusSession> login({
    required String studentId,
    required String password,
  });

  Future<void> logout(EcampusSession session);
}
