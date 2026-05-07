class EcampusSession {
  const EcampusSession({
    required this.cookies,
    required this.createdAt,
    this.lastUrl,
  });

  final Map<String, String> cookies;
  final DateTime createdAt;
  final String? lastUrl;

  bool get hasSessionCookie {
    final sessionId = cookies['JSESSIONID'];
    return sessionId != null && sessionId.trim().isNotEmpty;
  }

  bool get isEmpty => cookies.isEmpty || !hasSessionCookie;

  bool isOlderThan(Duration duration, DateTime now) {
    return now.difference(createdAt) > duration;
  }

  String get cookieHeader {
    return cookies.entries
        .where((entry) => entry.key.trim().isNotEmpty)
        .map((entry) => '${entry.key}=${entry.value}')
        .join('; ');
  }
}

abstract class EcampusAuthService {
  Future<void> logout(EcampusSession session);

  Future<void> clearSession();
}

abstract class EcampusCookieStore {
  Future<void> clearEcampusCookies();
}
