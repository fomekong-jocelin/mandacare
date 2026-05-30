import 'package:flutter/material.dart';

import '../../features/auth/data/auth_gateway.dart';
import '../../features/auth/domain/auth_session.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/patients/data/patient_gateway.dart';
import '../../features/tariff/data/tariff_gateway.dart';
import '../../features/users/data/user_gateway.dart';
import '../../features/more/data/clinic_gateway.dart';
import '../api/api_client.dart';
import '../api/api_config.dart';
import '../navigation/app_shell.dart';

class AppRouter extends StatefulWidget {
  const AppRouter({
    this.initialSession,
    this.authGateway,
    this.patientGateway,
    this.userGateway,
    this.tariffGateway,
    this.clinicGateway,
    super.key,
  });

  final AuthSession? initialSession;
  final AuthGateway? authGateway;
  final PatientGateway? patientGateway;
  final UserGateway? userGateway;
  final TariffGateway? tariffGateway;
  final ClinicGateway? clinicGateway;

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  late final ApiClient _apiClient;
  late final AuthGateway _authGateway;
  late final PatientGateway _patientGateway;
  late final UserGateway _userGateway;
  late final TariffGateway _tariffGateway;
  late final ClinicGateway _clinicGateway;
  AuthSession? _session;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient(baseUrl: ApiConfig.baseUrl);
    _authGateway = widget.authGateway ?? BackendAuthGateway(_apiClient);
    _patientGateway =
        widget.patientGateway ?? BackendPatientGateway(_apiClient);
    _userGateway = widget.userGateway ?? BackendUserGateway(_apiClient);
    _tariffGateway = widget.tariffGateway ?? BackendTariffGateway(_apiClient);
    _clinicGateway = widget.clinicGateway ?? BackendClinicGateway(_apiClient);
    _session = widget.initialSession;
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    if (session == null) {
      return LoginScreen(onLogin: _login);
    }
    return AppShell(
      session: session,
      patientGateway: _patientGateway,
      userGateway: _userGateway,
      tariffGateway: _tariffGateway,
      clinicGateway: _clinicGateway,
    );
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
