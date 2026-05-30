import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/presentation/layout/adaptive_layout.dart';
import '../../../shared/presentation/widgets/action_tile.dart';
import '../../../shared/presentation/widgets/feature_header.dart';
import '../../../shared/presentation/widgets/metric_strip.dart';
import '../../auth/domain/auth_session.dart';
import '../../consultations/domain/consultation_decision.dart';
import '../../patients/data/patient_gateway.dart';
import '../../patients/domain/patient_summary.dart';
import '../../patients/presentation/patient_detail_screen.dart';
import 'cashdesk_payment_sheet.dart';

class CashDeskScreen extends StatefulWidget {
  const CashDeskScreen({
    required this.session,
    required this.patientGateway,
    this.refreshRequestId = 0,
    this.onQueueChanged,
    super.key,
  });

  final AuthSession session;
  final PatientGateway patientGateway;
  final int refreshRequestId;
  final VoidCallback? onQueueChanged;

  @override
  State<CashDeskScreen> createState() => _CashDeskScreenState();
}

class _CashDeskScreenState extends State<CashDeskScreen> {
  List<_CashDeskPatient> _patients = const [];
  bool _loading = true;
  String? _error;
  String? _completingVisitId;

  @override
  void initState() {
    super.initState();
    _loadCashDeskQueue();
  }

  @override
  void didUpdateWidget(covariant CashDeskScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshRequestId != oldWidget.refreshRequestId) {
      _loadCashDeskQueue(showLoader: false);
    }
  }

  Future<void> _loadCashDeskQueue({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final queue = await widget.patientGateway.listTodayQueue(
        session: widget.session,
        status: PatientStatus.cashDesk,
        limit: 20,
      );
      final enrichedPatients = await Future.wait(
        queue.map(_withConsultationDecision),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _patients = enrichedPatients;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = 'Impossible de charger les patients en caisse.';
      });
    }
  }

  Future<_CashDeskPatient> _withConsultationDecision(
    PatientSummary patient,
  ) async {
    final patientId = patient.id;
    if (patientId == null) {
      return _CashDeskPatient(patient: patient);
    }

    try {
      final timeline = await widget.patientGateway.getPatientTimeline(
        session: widget.session,
        patientId: patientId,
      );
      return _CashDeskPatient(
        patient: patient,
        decision: timeline.isEmpty
            ? null
            : timeline.first.consultation?.decision,
      );
    } catch (_) {
      return _CashDeskPatient(patient: patient);
    }
  }

  Future<void> _openPatientDetail(PatientSummary patient) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => PatientDetailScreen(
          session: widget.session,
          patientGateway: widget.patientGateway,
          patient: patient,
        ),
      ),
    );
    if (changed == true) {
      widget.onQueueChanged?.call();
      await _loadCashDeskQueue(showLoader: false);
    }
  }

  Future<void> _completePayment(_CashDeskPatient item) async {
    final visitId = item.patient.latestVisitId;
    if (visitId == null) {
      _showMessage('Visite non synchronisée avec le serveur.');
      return;
    }

    final payload = await showCashDeskPaymentSheet(
      context,
      patientName: item.patient.fullName,
      targetLabel: _targetLabel(item.targetStatus),
    );
    if (payload == null) {
      return;
    }

    setState(() => _completingVisitId = visitId);
    try {
      final updatedPatient = await widget.patientGateway.completeCashDesk(
        session: widget.session,
        visitId: visitId,
        payload: payload,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _patients = _patients
            .where((patient) => patient.patient.latestVisitId != visitId)
            .toList(growable: false);
        _completingVisitId = null;
      });
      widget.onQueueChanged?.call();
      _showMessage(
        'Paiement validé - orientation ${_targetLabel(updatedPatient.status)}.',
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _completingVisitId = null);
      _showMessage('Impossible de valider le paiement.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          FeatureHeader(
            title: 'Caisse',
            subtitle: 'Patients à encaisser',
            actionIcon: Icons.refresh_rounded,
            actionTooltip: 'Actualiser',
            onActionPressed: () => _loadCashDeskQueue(showLoader: false),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadCashDeskQueue(showLoader: false),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      14,
                      16,
                      AdaptiveLayout.bottomContentPadding(context),
                    ),
                    sliver: SliverList.list(
                      children: [
                        _CashDeskSummaryCard(patients: _patients),
                        const SizedBox(height: 12),
                        _CashDeskMetrics(patients: _patients),
                        const SizedBox(height: 18),
                        const _SectionTitle(title: 'À encaisser'),
                        const SizedBox(height: 10),
                        if (_loading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 28),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (_error != null)
                          _CashDeskMessage(
                            icon: Icons.cloud_off_rounded,
                            title: 'Caisse indisponible',
                            message: _error!,
                            action: TextButton.icon(
                              onPressed: _loadCashDeskQueue,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Réessayer'),
                            ),
                          )
                        else if (_patients.isEmpty)
                          const _CashDeskMessage(
                            icon: Icons.price_check_rounded,
                            title: 'Aucun passage en caisse',
                            message:
                                'Les patients envoyés à la caisse apparaîtront ici.',
                          )
                        else
                          for (final item in _patients) ...[
                            _CashDeskPatientTile(
                              item: item,
                              completing:
                                  _completingVisitId ==
                                  item.patient.latestVisitId,
                              onOpen: () => _openPatientDetail(item.patient),
                              onComplete: () => _completePayment(item),
                            ),
                            const SizedBox(height: 10),
                          ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CashDeskPatient {
  const _CashDeskPatient({required this.patient, this.decision});

  final PatientSummary patient;
  final ConsultationDecision? decision;

  PatientStatus get targetStatus {
    return decision == ConsultationDecision.sendToLab
        ? PatientStatus.lab
        : PatientStatus.released;
  }
}

class _CashDeskSummaryCard extends StatelessWidget {
  const _CashDeskSummaryCard({required this.patients});

  final List<_CashDeskPatient> patients;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F0DE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.premiumGold.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Aujourd'hui",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${patients.length}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'patients en caisse',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.premiumGold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.58),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.payments_rounded,
              color: AppColors.premiumGold,
              size: 34,
            ),
          ),
        ],
      ),
    );
  }
}

class _CashDeskMetrics extends StatelessWidget {
  const _CashDeskMetrics({required this.patients});

  final List<_CashDeskPatient> patients;

  @override
  Widget build(BuildContext context) {
    final labCount = patients
        .where((patient) => patient.targetStatus == PatientStatus.lab)
        .length;
    final releaseCount = patients.length - labCount;

    return MetricStrip(
      items: [
        MetricStripItem(
          value: '${patients.length}',
          label: 'à encaisser',
          color: AppColors.premiumGold,
        ),
        MetricStripItem(
          value: '$labCount',
          label: 'vers labo',
          color: AppColors.info,
        ),
        MetricStripItem(
          value: '$releaseCount',
          label: 'vers sortie',
          color: AppColors.success,
        ),
      ],
    );
  }
}

class _CashDeskPatientTile extends StatelessWidget {
  const _CashDeskPatientTile({
    required this.item,
    required this.completing,
    required this.onOpen,
    required this.onComplete,
  });

  final _CashDeskPatient item;
  final bool completing;
  final VoidCallback onOpen;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final patient = item.patient;
    return ActionTile(
      icon: item.targetStatus == PatientStatus.lab
          ? Icons.science_rounded
          : Icons.logout_rounded,
      title: patient.fullName,
      subtitle:
          '${patient.reason} · ${_targetLabel(item.targetStatus)} · ${patient.lastVisit}',
      onTap: onOpen,
      trailing: FilledButton.icon(
        key: ValueKey('cashdesk-complete-${patient.latestVisitId}'),
        onPressed: completing ? null : onComplete,
        icon: completing
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.check_rounded, size: 18),
        label: const Text('Valider'),
        style: FilledButton.styleFrom(
          minimumSize: const Size(96, 38),
          backgroundColor: AppColors.medicalGreen,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _CashDeskMessage extends StatelessWidget {
  const _CashDeskMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: [
          Icon(icon, color: AppColors.premiumGold, size: 30),
          const SizedBox(height: 8),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (action != null) ...[const SizedBox(height: 8), action!],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: AppColors.deepHealthBlue,
        fontSize: 15.5,
        fontWeight: FontWeight.w700,
        height: 1.12,
      ),
    );
  }
}

String _targetLabel(PatientStatus status) {
  return switch (status) {
    PatientStatus.lab => 'vers labo',
    PatientStatus.released => 'vers sortie',
    _ => status.label,
  };
}
