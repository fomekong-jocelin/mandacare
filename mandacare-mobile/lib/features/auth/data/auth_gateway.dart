import '../../../app/api/api_client.dart';
import '../domain/auth_session.dart';

abstract class AuthGateway {
  Future<AuthSession> login({
    required String username,
    required String password,
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
    return AuthSession(
      accessToken: response['accessToken'] as String,
      username: response['username'] as String,
      displayName: response['displayName'] as String,
    );
  }
}
