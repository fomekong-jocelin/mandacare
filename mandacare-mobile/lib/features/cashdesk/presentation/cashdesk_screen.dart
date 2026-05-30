import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/presentation/layout/adaptive_layout.dart';
import '../../../shared/presentation/widgets/feature_header.dart';
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
            subtitle: 'Encaissement des dossiers orientés par consultation',
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
                        _CashDeskOverview(patients: _patients),
                        const SizedBox(height: 18),
                        const _SectionTitle(title: 'Dossiers à encaisser'),
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

class _CashDeskOverview extends StatelessWidget {
  const _CashDeskOverview({required this.patients});

  final List<_CashDeskPatient> patients;

  @override
  Widget build(BuildContext context) {
    final labCount = patients
        .where((patient) => patient.targetStatus == PatientStatus.lab)
        .length;
    final releaseCount = patients.length - labCount;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vue opérationnelle',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.deepHealthBlue,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _CashDeskKpi(
                  value: '${patients.length}',
                  label: 'En attente',
                  icon: Icons.point_of_sale_rounded,
                  color: AppColors.premiumGold,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CashDeskKpi(
                  value: '$labCount',
                  label: 'Vers labo',
                  icon: Icons.science_rounded,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CashDeskKpi(
                  value: '$releaseCount',
                  label: 'Vers sortie',
                  icon: Icons.logout_rounded,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CashDeskKpi extends StatelessWidget {
  const _CashDeskKpi({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
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
    final targetStatus = item.targetStatus;
    final targetColor = targetStatus == PatientStatus.lab
        ? AppColors.info
        : AppColors.success;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 420;
              final details = _CashDeskPatientDetails(
                patient: patient,
                targetColor: targetColor,
                targetStatus: targetStatus,
              );
              final actions = _CashDeskPatientActions(
                completing: completing,
                onOpen: onOpen,
                onComplete: onComplete,
                visitId: patient.latestVisitId,
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [details, const SizedBox(height: 12), actions],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: details),
                  const SizedBox(width: 12),
                  actions,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CashDeskPatientDetails extends StatelessWidget {
  const _CashDeskPatientDetails({
    required this.patient,
    required this.targetStatus,
    required this.targetColor,
  });

  final PatientSummary patient;
  final PatientStatus targetStatus;
  final Color targetColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.deepHealthBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.receipt_long_rounded,
            color: AppColors.deepHealthBlue,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      patient.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _CashDeskRouteBadge(
                    label: _targetLabel(targetStatus),
                    color: targetColor,
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                '${patient.patientNumber ?? 'Dossier non numéroté'} · ${patient.reason}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${patient.phoneNumber} · ${patient.lastVisit}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CashDeskRouteBadge extends StatelessWidget {
  const _CashDeskRouteBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}

class _CashDeskPatientActions extends StatelessWidget {
  const _CashDeskPatientActions({
    required this.completing,
    required this.onOpen,
    required this.onComplete,
    required this.visitId,
  });

  final bool completing;
  final VoidCallback onOpen;
  final VoidCallback onComplete;
  final String? visitId;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: [
        OutlinedButton.icon(
          onPressed: onOpen,
          icon: const Icon(Icons.folder_open_rounded, size: 18),
          label: const Text('Dossier'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(104, 38),
            foregroundColor: AppColors.deepHealthBlue,
            side: BorderSide(
              color: AppColors.deepHealthBlue.withValues(alpha: 0.22),
            ),
          ),
        ),
        FilledButton.icon(
          key: ValueKey('cashdesk-complete-$visitId'),
          onPressed: completing ? null : onComplete,
          icon: completing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.point_of_sale_rounded, size: 18),
          label: const Text('Encaisser'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(118, 38),
            backgroundColor: AppColors.medicalGreen,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.45)),
      ),
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
