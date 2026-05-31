import 'package:flutter/material.dart';

import '../../features/cashdesk/presentation/cashdesk_screen.dart';
import '../../features/consultations/presentation/consultation_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/auth/data/auth_gateway.dart';
import '../../features/auth/domain/auth_session.dart';
import '../../features/more/data/clinic_gateway.dart';
import '../../features/more/presentation/more_screen.dart';
import '../../features/patients/data/patient_gateway.dart';
import '../../features/patients/presentation/patient_filter.dart';
import '../../features/patients/presentation/patient_list_screen.dart';
import '../../features/tariff/data/tariff_gateway.dart';
import '../../features/users/data/user_gateway.dart';
import '../../shared/presentation/layout/adaptive_layout.dart';
import 'app_tab.dart';
import 'floating_bottom_nav.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    required this.session,
    required this.patientGateway,
    required this.userGateway,
    required this.tariffGateway,
    required this.clinicGateway,
    required this.authGateway,
    required this.onLogout,
    required this.onSessionChanged,
    super.key,
  });

  final AuthSession session;
  final PatientGateway patientGateway;
  final UserGateway userGateway;
  final TariffGateway tariffGateway;
  final ClinicGateway clinicGateway;
  final AuthGateway authGateway;
  final VoidCallback onLogout;
  final ValueChanged<AuthSession> onSessionChanged;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = AppTab.home.index;
  int _dashboardRefreshRequestId = 0;
  int _patientFilterRequestId = 0;
  int _consultationRefreshRequestId = 0;
  int _cashDeskRefreshRequestId = 0;
  PatientFilter _requestedPatientFilter = PatientFilter.all;

  @override
  Widget build(BuildContext context) {
    final body = IndexedStack(
      index: _currentIndex,
      children: [
        DashboardScreen(
          session: widget.session,
          patientGateway: widget.patientGateway,
          refreshRequestId: _dashboardRefreshRequestId,
          connectedUserName: widget.session.displayName,
          connectedUserRole: widget.session.roleLabel,
          onOpenPatients: _openPatients,
          onOpenConsultations: () => _openTab(AppTab.consultations),
          onOpenCashDesk: () => _openTab(AppTab.cashDesk),
        ),
        PatientListScreen(
          session: widget.session,
          patientGateway: widget.patientGateway,
          requestedFilter: _requestedPatientFilter,
          filterRequestId: _patientFilterRequestId,
          onQueueChanged: _requestDashboardRefresh,
        ),
        ConsultationScreen(
          session: widget.session,
          patientGateway: widget.patientGateway,
          refreshRequestId: _consultationRefreshRequestId,
        ),
        CashDeskScreen(
          session: widget.session,
          patientGateway: widget.patientGateway,
          refreshRequestId: _cashDeskRefreshRequestId,
          onQueueChanged: _requestDashboardRefresh,
        ),
        MoreScreen(
          session: widget.session,
          userGateway: widget.userGateway,
          tariffGateway: widget.tariffGateway,
          clinicGateway: widget.clinicGateway,
          patientGateway: widget.patientGateway,
          authGateway: widget.authGateway,
          onLogout: widget.onLogout,
          onSessionChanged: widget.onSessionChanged,
        ),
      ],
    );

    if (AdaptiveLayout.useSideNavigation(context)) {
      return Scaffold(
        body: Row(
          children: [
            FloatingSideNav(currentIndex: _currentIndex, onChanged: _openIndex),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      extendBody: true,
      body: body,
      bottomNavigationBar: FloatingBottomNav(
        currentIndex: _currentIndex,
        onChanged: _openIndex,
      ),
    );
  }

  void _openPatients(PatientFilter filter) {
    setState(() {
      _requestedPatientFilter = filter;
      _patientFilterRequestId++;
      _currentIndex = AppTab.patients.index;
    });
  }

  void _openTab(AppTab tab) {
    _openIndex(tab.index);
  }

  void _openIndex(int index) {
    setState(() {
      _currentIndex = index;
      if (index == AppTab.home.index) {
        _dashboardRefreshRequestId++;
      }
      if (index == AppTab.consultations.index) {
        _consultationRefreshRequestId++;
      }
      if (index == AppTab.cashDesk.index) {
        _cashDeskRefreshRequestId++;
      }
    });
  }

  void _requestDashboardRefresh() {
    setState(() {
      _dashboardRefreshRequestId++;
    });
  }
}
