import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/presentation/layout/adaptive_layout.dart';
import '../../auth/domain/auth_session.dart';
import '../../consultations/presentation/vitals_form_screen.dart';
import '../../consultations/presentation/consultation_form_screen.dart';
import '../../patients/data/patient_gateway.dart';
import '../../patients/domain/patient_summary.dart';
import '../../patients/domain/vitals_summary.dart';
import '../../patients/presentation/patient_filter.dart';
import '../../patients/presentation/patient_form_screen.dart';
import '../../patients/presentation/patient_detail_screen.dart';
import 'widgets/quick_actions_grid.dart';
import 'widgets/queue_panel.dart';
import 'widgets/section_header.dart';
import 'widgets/today_status_grid.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    required this.session,
    required this.patientGateway,
    required this.onOpenPatients,
    required this.onOpenConsultations,
    required this.onOpenCashDesk,
    super.key,
    this.connectedUserName = 'Dr Manda',
  });

  final AuthSession session;
  final PatientGateway patientGateway;
  final ValueChanged<PatientFilter> onOpenPatients;
  final VoidCallback onOpenConsultations;
  final VoidCallback onOpenCashDesk;
  final String connectedUserName;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<PatientSummary> _queue = const [];
  bool _loadingQueue = true;
  String? _queueError;

  @override
  void initState() {
    super.initState();
    _loadQueue();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= 720;
          return Column(
            children: [
              _Header(
                isTablet: isTablet,
                connectedUserName: widget.connectedUserName,
              ),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      sliver: SliverList.list(
                        children: [
                          TodayStatusGrid(isTablet: isTablet),
                          const SizedBox(height: 16),
                          const SectionHeader(
                            title: 'Accès rapide',
                            actionLabel: 'Tout voir',
                          ),
                          const SizedBox(height: 10),
                          QuickActionsGrid(
                            isTablet: isTablet,
                            onCreatePatient: _openCreatePatient,
                            onOpenPatients: widget.onOpenPatients,
                            onOpenConsultations: widget.onOpenConsultations,
                            onOpenCashDesk: widget.onOpenCashDesk,
                          ),
                          const SizedBox(height: 16),
                          SectionHeader(
                            title: "File d'attente",
                            actionLabel: 'Voir tout',
                            onActionPressed: () {
                              widget.onOpenPatients(PatientFilter.waiting);
                            },
                          ),
                          const SizedBox(height: 10),
                          QueuePanel(
                            patients: _queue,
                            loading: _loadingQueue,
                            error: _queueError,
                            onRetry: _loadQueue,
                            onStatusChanged: _changeVisitStatus,
                            onVitalsPressed: _openVitalsForm,
                            onConsultationPressed: _openConsultationForm,
                            onPatientTap: _openPatientDetail,
                          ),
                          SizedBox(
                            height: AdaptiveLayout.bottomContentPadding(
                              context,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _loadQueue() async {
    setState(() {
      _loadingQueue = true;
      _queueError = null;
    });

    try {
      final queue = await widget.patientGateway.listTodayQueue(
        session: widget.session,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _queue = queue;
        _loadingQueue = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingQueue = false;
        _queueError = "Impossible de charger la file d'attente.";
      });
    }
  }

  Future<void> _openCreatePatient() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => PatientFormScreen(
          session: widget.session,
          patientGateway: widget.patientGateway,
        ),
      ),
    );
    if (created == true) {
      await _loadQueue();
    }
  }

  Future<void> _changeVisitStatus(
    PatientSummary patient,
    PatientStatus status,
  ) async {
    final visitId = patient.latestVisitId ?? await _refreshVisitIdFor(patient);
    if (visitId == null) {
      _showMessage('Visite non synchronisée avec le serveur.');
      return;
    }

    try {
      await widget.patientGateway.changeVisitStatus(
        session: widget.session,
        visitId: visitId,
        status: status,
      );
      await _loadQueue();
    } catch (_) {
      _showMessage('Impossible de changer le statut de la visite.');
    }
  }

  Future<void> _openVitalsForm(PatientSummary patient) async {
    final visitId = patient.latestVisitId ?? await _refreshVisitIdFor(patient);
    if (visitId == null) {
      _showMessage('Visite non synchronisée avec le serveur.');
      return;
    }
    if (!mounted) {
      return;
    }

    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => VitalsFormScreen(
          session: widget.session,
          patientGateway: widget.patientGateway,
          patient: patient,
          visitId: visitId,
        ),
      ),
    );
    if (saved == true) {
      await _loadQueue();
    }
  }

  void _openPatientDetail(PatientSummary patient) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => PatientDetailScreen(
              session: widget.session,
              patientGateway: widget.patientGateway,
              patient: patient,
            ),
          ),
        )
        .then((_) => _loadQueue());
  }

  Future<void> _openConsultationForm(PatientSummary patient) async {
    final visitId = patient.latestVisitId ?? await _refreshVisitIdFor(patient);
    if (visitId == null) {
      _showMessage('Visite non synchronisée avec le serveur.');
      return;
    }

    setState(() => _loadingQueue = true);
    VitalsSummary? vitals;
    try {
      vitals = await widget.patientGateway.getLatestVitals(
        session: widget.session,
        visitId: visitId,
      );
    } catch (_) {
      // It's ok if there are no vitals
    } finally {
      if (mounted) {
        setState(() => _loadingQueue = false);
      }
    }

    if (!mounted) {
      return;
    }

    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ConsultationFormScreen(
          session: widget.session,
          patientGateway: widget.patientGateway,
          patient: patient,
          visitId: visitId,
          vitals: vitals,
        ),
      ),
    );
    if (saved == true) {
      await _loadQueue();
    }
  }

  Future<String?> _refreshVisitIdFor(PatientSummary patient) async {
    try {
      final queue = await widget.patientGateway.listTodayQueue(
        session: widget.session,
      );
      if (!mounted) {
        return null;
      }
      setState(() {
        _queue = queue;
        _loadingQueue = false;
        _queueError = null;
      });
      return _matchingPatient(queue, patient)?.latestVisitId;
    } catch (_) {
      return null;
    }
  }

  PatientSummary? _matchingPatient(
    List<PatientSummary> queue,
    PatientSummary selected,
  ) {
    for (final patient in queue) {
      if (selected.id != null && patient.id == selected.id) {
        return patient;
      }
      if (patient.fullName == selected.fullName) {
        return patient;
      }
    }
    return null;
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.isTablet, required this.connectedUserName});

  final bool isTablet;
  final String connectedUserName;

  @override
  Widget build(BuildContext context) {
    final compact = AdaptiveLayout.useSideNavigation(context);
    final logoWidth = isTablet ? 172.0 : 132.0;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.lightBackground.withValues(alpha: 0.98),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepHealthBlue.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, compact ? 8 : 8, 16, compact ? 8 : 12),
        child: compact
            ? Row(
                children: [
                  Image.asset(
                    'assets/brand/mandacare_logo_horizontal.png',
                    width: 116,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _GreetingText(
                      connectedUserName: connectedUserName,
                      isTablet: isTablet,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const _TodayChip(),
                  const SizedBox(width: 8),
                  const _HeaderActions(),
                ],
              )
            : Column(
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/brand/mandacare_logo_horizontal.png',
                        width: logoWidth,
                        fit: BoxFit.contain,
                      ),
                      const Spacer(),
                      const _HeaderActions(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _GreetingText(
                          connectedUserName: connectedUserName,
                          isTablet: isTablet,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const _TodayChip(),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

class _HeaderActions extends StatelessWidget {
  const _HeaderActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          onPressed: () {},
          tooltip: 'Notifications',
          style: IconButton.styleFrom(
            fixedSize: const Size(42, 42),
            backgroundColor: AppColors.medicalGreen.withValues(alpha: 0.10),
          ),
          icon: const Icon(Icons.notifications_none_rounded),
        ),
        const SizedBox(width: 8),
        const CircleAvatar(
          radius: 21,
          backgroundColor: AppColors.deepHealthBlue,
          child: Text('DM', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

class _GreetingText extends StatelessWidget {
  const _GreetingText({
    required this.connectedUserName,
    required this.isTablet,
  });

  final String connectedUserName;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bonjour, $connectedUserName',
          maxLines: 1,
          overflow: TextOverflow.fade,
          softWrap: false,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.deepHealthBlue,
            fontSize: isTablet ? 22 : 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Activité de la clinique',
          maxLines: 1,
          overflow: TextOverflow.fade,
          softWrap: false,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _TodayChip extends StatelessWidget {
  const _TodayChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.medicalGreen.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        "Aujourd'hui",
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.medicalGreen,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
