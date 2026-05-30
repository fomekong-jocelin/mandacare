class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.username,
    required this.displayName,
    this.roleCode = 'AUTRE',
    this.roleLabel = 'Utilisateur',
    this.roleDescription,
    this.phone,
    this.email,
  });

  final String accessToken;
  final String username;
  final String displayName;
  final String roleCode;
  final String roleLabel;
  final String? roleDescription;
  final String? phone;
  final String? email;

  String get initials {
    final parts = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.substring(0, 1).toUpperCase());
    final value = parts.join();
    return value.isEmpty ? 'U' : value;
  }
}
