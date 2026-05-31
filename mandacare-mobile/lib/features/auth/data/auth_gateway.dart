import '../../../app/api/api_client.dart';
import '../domain/auth_session.dart';

abstract class AuthGateway {
  Future<AuthSession> login({
    required String username,
    required String password,
  });
  Future<AuthSession> getProfile({required String accessToken});
  Future<AuthSession> updateProfile({
    required String accessToken,
    required String firstName,
    required String lastName,
    String? phone,
    String? email,
    String? password,
  });
}

class BackendAuthGateway implements AuthGateway {
  const BackendAuthGateway(this.apiClient);

  final ApiClient apiClient;

  @override
  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    final response = await apiClient.postJson('/auth/login', {
      'username': username,
      'password': password,
    });
    final profile = _readMap(response['profile']) ?? response;
    final role = _readMap(profile['role']) ?? const <String, dynamic>{};
    return AuthSession(
      accessToken: response['accessToken'] as String,
      username:
          _readString(profile['username']) ?? (response['username'] as String),
      displayName:
          _readString(profile['displayName']) ??
          (response['displayName'] as String),
      roleCode: _readString(role['code']) ?? 'AUTRE',
      roleLabel: _readString(role['label']) ?? 'Utilisateur',
      roleDescription: _readString(role['description']),
      phone: _readString(profile['phone']),
      email: _readString(profile['email']),
    );
  }

  @override
  Future<AuthSession> getProfile({required String accessToken}) async {
    final response = await apiClient.getJson(
      '/auth/profile',
      token: accessToken,
    );
    final role = _readMap(response['role']) ?? const <String, dynamic>{};
    return AuthSession(
      accessToken: accessToken,
      username: response['username'] as String,
      displayName: response['displayName'] as String,
      roleCode: _readString(role['code']) ?? 'AUTRE',
      roleLabel: _readString(role['label']) ?? 'Utilisateur',
      roleDescription: _readString(role['description']),
      phone: _readString(response['phone']),
      email: _readString(response['email']),
    );
  }

  @override
  Future<AuthSession> updateProfile({
    required String accessToken,
    required String firstName,
    required String lastName,
    String? phone,
    String? email,
    String? password,
  }) async {
    final response = await apiClient.putJson(
      '/auth/profile',
      {
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'email': email,
        'password': password,
      },
      token: accessToken,
    );
    final role = _readMap(response['role']) ?? const <String, dynamic>{};
    return AuthSession(
      accessToken: accessToken,
      username: response['username'] as String,
      displayName: response['displayName'] as String,
      roleCode: _readString(role['code']) ?? 'AUTRE',
      roleLabel: _readString(role['label']) ?? 'Utilisateur',
      roleDescription: _readString(role['description']),
      phone: _readString(response['phone']),
      email: _readString(response['email']),
    );
  }

  Map<String, dynamic>? _readMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    return null;
  }

  String? _readString(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    return null;
  }
}
