import 'package:flutter/material.dart';

import '../../features/cashdesk/presentation/cashdesk_screen.dart';
import '../../features/consultations/presentation/consultation_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/auth/domain/auth_session.dart';
import '../../features/more/presentation/more_screen.dart';
import '../../features/patients/data/patient_gateway.dart';
import '../../features/patients/presentation/patient_filter.dart';
import '../../features/patients/presentation/patient_list_screen.dart';
import '../../shared/presentation/layout/adaptive_layout.dart';
import 'app_tab.dart';
import 'floating_bottom_nav.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    required this.session,
    required this.patientGateway,
    super.key,
  });

  final AuthSession session;
  final PatientGateway patientGateway;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = AppTab.home.index;
  int _patientFilterRequestId = 0;
  int _consultationRefreshRequestId = 0;
  PatientFilter _requestedPatientFilter = PatientFilter.all;

  @override
  Widget build(BuildContext context) {
    final body = IndexedStack(
      index: _currentIndex,
      children: [
        DashboardScreen(
          session: widget.session,
          patientGateway: widget.patientGateway,
          connectedUserName: widget.session.displayName,
          onOpenPatients: _openPatients,
          onOpenConsultations: () => _openTab(AppTab.consultations),
          onOpenCashDesk: () => _openTab(AppTab.cashDesk),
        ),
        PatientListScreen(
          session: widget.session,
          patientGateway: widget.patientGateway,
          requestedFilter: _requestedPatientFilter,
          filterRequestId: _patientFilterRequestId,
        ),
        ConsultationScreen(
          session: widget.session,
          patientGateway: widget.patientGateway,
          refreshRequestId: _consultationRefreshRequestId,
        ),
        const CashDeskScreen(),
        const MoreScreen(),
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
      if (index == AppTab.consultations.index) {
        _consultationRefreshRequestId++;
      }
    });
  }
}
