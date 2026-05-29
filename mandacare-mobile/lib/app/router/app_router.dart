import 'package:flutter/material.dart';

import '../../features/auth/data/auth_gateway.dart';
import '../../features/auth/domain/auth_session.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/patients/data/patient_gateway.dart';
import '../api/api_client.dart';
import '../api/api_config.dart';
import '../navigation/app_shell.dart';

class AppRouter extends StatefulWidget {
  const AppRouter({
    this.initialSession,
    this.authGateway,
    this.patientGateway,
    super.key,
  });

  final AuthSession? initialSession;
  final AuthGateway? authGateway;
  final PatientGateway? patientGateway;

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  late final ApiClient _apiClient;
  late final AuthGateway _authGateway;
  late final PatientGateway _patientGateway;
  AuthSession? _session;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient(baseUrl: ApiConfig.baseUrl);
    _authGateway = widget.authGateway ?? BackendAuthGateway(_apiClient);
    _patientGateway =
        widget.patientGateway ?? BackendPatientGateway(_apiClient);
    _session = widget.initialSession;
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    if (session == null) {
      return LoginScreen(onLogin: _login);
    }
    return AppShell(session: session, patientGateway: _patientGateway);
  }

  Future<AuthSession> _login(String username, String password) async {
    final session = await _authGateway.login(
      username: username,
      password: password,
    );
    if (mounted) {
      setState(() => _session = session);
    }
    return session;
  }
}
