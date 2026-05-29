class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.username,
    required this.displayName,
  });

  final String accessToken;
  final String username;
  final String displayName;
}
