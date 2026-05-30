import '../../../app/api/api_client.dart';
import '../../auth/domain/auth_session.dart';
import '../domain/team_user.dart';
import '../domain/user_payload.dart';
import '../domain/user_role.dart';

abstract class UserGateway {
  Future<List<UserRole>> listRoles({required AuthSession session});

  Future<List<TeamUser>> listUsers({required AuthSession session});

  Future<TeamUser> createUser({
    required AuthSession session,
    required CreateTeamUserPayload payload,
  });

  Future<TeamUser> updateUser({
    required AuthSession session,
    required String id,
    required UpdateTeamUserPayload payload,
  });
}

class BackendUserGateway implements UserGateway {
  const BackendUserGateway(this.apiClient);

  final ApiClient apiClient;

  @override
  Future<List<UserRole>> listRoles({required AuthSession session}) async {
    final response = await apiClient.getJsonList(
      '/auth/roles',
      token: session.accessToken,
    );
    return response
        .whereType<Map<String, dynamic>>()
        .map(_UserMapper.roleFromJson)
        .toList(growable: false);
  }

  @override
  Future<List<TeamUser>> listUsers({required AuthSession session}) async {
    final response = await apiClient.getJsonList(
      '/auth/users',
      token: session.accessToken,
    );
    return response
        .whereType<Map<String, dynamic>>()
        .map(_UserMapper.userFromJson)
        .toList(growable: false);
  }

  @override
  Future<TeamUser> createUser({
    required AuthSession session,
    required CreateTeamUserPayload payload,
  }) async {
    final response = await apiClient.postJson(
      '/auth/users',
      payload.toJson(),
      token: session.accessToken,
    );
    return _UserMapper.userFromJson(response);
  }

  @override
  Future<TeamUser> updateUser({
    required AuthSession session,
    required String id,
    required UpdateTeamUserPayload payload,
  }) async {
    final response = await apiClient.patchJson(
      '/auth/users/$id',
      payload.toJson(),
      token: session.accessToken,
    );
    return _UserMapper.userFromJson(response);
  }
}

class _UserMapper {
  const _UserMapper._();

  static TeamUser userFromJson(Map<String, dynamic> json) {
    final role = json['role'];
    return TeamUser(
      id: json['id'] as String,
      username: json['username'] as String,
      displayName: json['displayName'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      phone: _readString(json['phone']),
      email: _readString(json['email']),
      status: json['status'] as String,
      role: role is Map<String, dynamic>
          ? roleFromJson(role)
          : const UserRole(code: 'AUTRE', label: 'Autre profil'),
      lastLoginAt: _readDate(json['lastLoginAt']),
    );
  }

  static UserRole roleFromJson(Map<String, dynamic> json) {
    return UserRole(
      code: json['code'] as String,
      label: json['label'] as String,
      description: _readString(json['description']),
    );
  }

  static String? _readString(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    return null;
  }

  static DateTime? _readDate(Object? value) {
    if (value is! String || value.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }
}
