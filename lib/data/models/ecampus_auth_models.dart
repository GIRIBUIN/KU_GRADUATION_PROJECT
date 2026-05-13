class EcampusLoginDetectionResult {
  const EcampusLoginDetectionResult({
    required this.hasUser,
    required this.hasLogoutButton,
    required this.hasLogoutLink,
    required this.hasTodoList,
    required this.hasSessionCookie,
  });

  final bool hasUser;
  final bool hasLogoutButton;
  final bool hasLogoutLink;
  final bool hasTodoList;
  final bool hasSessionCookie;

  bool get isLoggedIn =>
      hasUser && hasLogoutButton && hasLogoutLink && hasSessionCookie;
}
