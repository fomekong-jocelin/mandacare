import 'user_role.dart';

class TeamUser {
  const TeamUser({
    required this.id,
    required this.username,
    required this.displayName,
    required this.firstName,
    required this.lastName,
    required this.status,
    required this.role,
    this.phone,
    this.email,
    this.lastLoginAt,
  });

  final String id;
  final String username;
  final String displayName;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? email;
  final String status;
  final UserRole role;
  final DateTime? lastLoginAt;

  bool get active => status == 'ACTIVE';
}
