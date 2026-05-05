class EcampusSession {
  const EcampusSession({
    required this.cookies,
    required this.createdAt,
  });

  final Map<String, String> cookies;
  final DateTime createdAt;
}

abstract class EcampusAuthService {
  Future<EcampusSession> login({
    required String studentId,
    required String password,
  });

  Future<void> logout(EcampusSession session);
}
