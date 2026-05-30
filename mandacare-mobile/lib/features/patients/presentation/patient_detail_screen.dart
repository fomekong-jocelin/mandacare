import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../consultations/domain/consultation_decision.dart';
import '../../consultations/domain/prescription.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/presentation/widgets/action_tile.dart';
import '../../../shared/presentation/widgets/metric_strip.dart';
import '../../../shared/presentation/widgets/page_header.dart';
import '../../auth/domain/auth_session.dart';
import '../../cashdesk/presentation/cashdesk_payment_sheet.dart';
import '../data/patient_gateway.dart';
import '../domain/patient_summary.dart';
import '../domain/patient_timeline_item.dart';
import '../../consultations/presentation/vitals_form_screen.dart';
import '../../consultations/presentation/consultation_form_screen.dart';
import 'patient_visit_form_screen.dart';
import 'widgets/patient_status_badge.dart';

class PatientDetailScreen extends StatefulWidget {
  const PatientDetailScreen({
    required this.session,
    required this.patientGateway,
    required this.patient,
    super.key,
  });

  final AuthSession session;
  final PatientGateway patientGateway;
  final PatientSummary patient;

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  List<PatientTimelineItem> _timeline = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTimeline();
  }

  Future<void> _loadTimeline() async {
    final patientId = widget.patient.id;
    if (patientId == null) {
      setState(() {
        _loading = false;
        _error = 'ID patient absent.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await widget.patientGateway.getPatientTimeline(
        session: widget.session,
        patientId: patientId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _timeline = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Impossible de charger l\'historique.';
        _loading = false;
      });
    }
  }

  Future<void> _viewPrescriptionDetail(PatientTimelineItem item) async {
    final consultation = item.consultation;
    if (consultation == null) {
      return;
    }

    setState(() => _loading = true);
    try {
      final Prescription? prescription = await widget.patientGateway
          .getPrescription(
            session: widget.session,
            consultationId: consultation.id,
          );
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);

      if (prescription == null) {
        _showMessage('Aucune ordonnance associée à cette consultation.');
        return;
      }

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ordonnance ${prescription.prescriptionNumber}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.deepHealthBlue,
                              ),
                            ),
                            Text(
                              'Réf. Consultation : ${consultation.diagnosis}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (prescription.items.isEmpty)
                        const Center(
                          child: Text(
                            'Aucun médicament prescrit dans cette ordonnance.',
                          ),
                        )
                      else
                        ...prescription.items.map((drug) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.lightBackground.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.border.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.medication_rounded,
                                      color: AppColors.medicalGreen,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        drug.drugName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14.5,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 4,
                                  children: [
                                    if (drug.form != null)
                                      _DrugDetailTag(
                                        label: 'Forme: ${drug.form}',
                                      ),
                                    if (drug.dosage != null)
                                      _DrugDetailTag(
                                        label: 'Dosage: ${drug.dosage}',
                                      ),
                                    if (drug.frequency != null)
                                      _DrugDetailTag(
                                        label: 'Fréq: ${drug.frequency}',
                                      ),
                                    if (drug.duration != null)
                                      _DrugDetailTag(
                                        label: 'Durée: ${drug.duration}',
                                      ),
                                    if (drug.quantity != null)
                                      _DrugDetailTag(
                                        label: 'Qté: ${drug.quantity} boîtes',
                                      ),
                                  ],
                                ),
                                if (drug.instructions != null) ...[
                                  const SizedBox(height: 8),
                                  const Divider(height: 12),
                                  Text(
                                    'Instructions: ${drug.instructions}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: FilledButton.icon(
                          onPressed: () async {
                            String relativeUrl =
                                prescription.pdfUrl ??
                                '/consultations/${consultation.id}/prescription/pdf';
                            final baseUrl =
                                widget.patientGateway is BackendPatientGateway
                                ? (widget.patientGateway
                                          as BackendPatientGateway)
                                      .apiClient
                                      .baseUrl
                                : "http://localhost:8080/api/v1";

                            if (relativeUrl.startsWith('/api/v1/')) {
                              if (baseUrl.endsWith('/api/v1')) {
                                relativeUrl = relativeUrl.substring(7);
                              }
                            } else if (!relativeUrl.startsWith('/')) {
                              relativeUrl = '/$relativeUrl';
                            }

                            final fullUrl = '$baseUrl$relativeUrl';
                            final url = Uri.parse(fullUrl);

                            try {
                              final success = await launchUrl(
                                url,
                                mode: LaunchMode.externalApplication,
                              );
                              if (!success) {
                                _showMessage('Impossible d\'ouvrir le PDF.');
                              }
                            } catch (_) {
                              _showMessage('Impossible d\'ouvrir le PDF.');
                            }
                          },
                          icon: const Icon(Icons.print_rounded),
                          label: const Text('Prévisualiser & Imprimer'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.medicalGreen,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () async {
                          String relativeUrl =
                              prescription.pdfUrl ??
                              '/consultations/${consultation.id}/prescription/pdf';
                          final baseUrl =
                              widget.patientGateway is BackendPatientGateway
                              ? (widget.patientGateway as BackendPatientGateway)
                                    .apiClient
                                    .baseUrl
                              : "http://localhost:8080/api/v1";

                          if (relativeUrl.startsWith('/api/v1/')) {
                            if (baseUrl.endsWith('/api/v1')) {
                              relativeUrl = relativeUrl.substring(7);
                            }
                          } else if (!relativeUrl.startsWith('/')) {
                            relativeUrl = '/$relativeUrl';
                          }

                          final fullUrl = '$baseUrl$relativeUrl';
                          await Clipboard.setData(ClipboardData(text: fullUrl));
                          _showMessage(
                            'Lien PDF de l\'ordonnance copié dans le presse-papiers.',
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          padding: EdgeInsets.zero,
                        ),
                        child: const Icon(Icons.copy_all_rounded),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (_) {
      setState(() => _loading = false);
      _showMessage('Impossible de charger les détails de l\'ordonnance.');
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

  PatientStatus get _currentStatus {
    if (_timeline.isNotEmpty) {
      return _timeline.first.status;
    }
    return widget.patient.status;
  }

  PatientTimelineItem? get _latestVisit {
    if (_timeline.isEmpty) {
      return null;
    }
    return _timeline.first;
  }

  bool get _hasActiveVisit {
    final latestVisit = _latestVisit;
    if (latestVisit == null || latestVisit.status == PatientStatus.released) {
      return false;
    }

    final now = DateTime.now();
    return latestVisit.arrivalAt.year == now.year &&
        latestVisit.arrivalAt.month == now.month &&
        latestVisit.arrivalAt.day == now.day;
  }

  ConsultationDecision? get _latestConsultationDecision {
    return _latestVisit?.consultation?.decision;
  }

  PatientStatus get _statusAfterCashDesk {
    return switch (_latestConsultationDecision) {
      ConsultationDecision.sendToLab => PatientStatus.lab,
      _ => PatientStatus.released,
    };
  }

  Future<void> _completeCashDeskStep() async {
    final latestVisit = _latestVisit;
    if (latestVisit == null) {
      _showMessage('Visite non synchronisée avec le serveur.');
      return;
    }

    final payload = await showCashDeskPaymentSheet(
      context,
      patientName: widget.patient.fullName,
      targetLabel: _statusAfterCashDesk == PatientStatus.lab
          ? 'vers labo'
          : 'vers sortie',
    );
    if (payload == null) {
      return;
    }

    try {
      await widget.patientGateway.completeCashDesk(
        session: widget.session,
        visitId: latestVisit.visitId,
        payload: payload,
      );
      if (mounted) {
        await _loadTimeline();
      }
    } catch (_) {
      _showMessage('Impossible de valider le passage en caisse.');
    }
  }

  Future<void> _openVitalsForm() async {
    if (_timeline.isEmpty) return;
    final latestItem = _timeline.first;
    final visitId = latestItem.visitId;

    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => VitalsFormScreen(
          session: widget.session,
          patientGateway: widget.patientGateway,
          patient: widget.patient,
          visitId: visitId,
        ),
      ),
    );
    if (saved == true && mounted) {
      _loadTimeline();
    }
  }

  Future<void> _openConsultationForm() async {
    if (_timeline.isEmpty) return;
    final latestItem = _timeline.first;
    final visitId = latestItem.visitId;

    setState(() => _loading = true);
    try {
      final vitals = await widget.patientGateway.getLatestVitals(
        session: widget.session,
        visitId: visitId,
      );

      // Transition status to inConsultation if the status is currently waiting
      if (_currentStatus == PatientStatus.waiting) {
        await widget.patientGateway.changeVisitStatus(
          session: widget.session,
          visitId: visitId,
          status: PatientStatus.inConsultation,
        );
      }

      if (!mounted) return;
      setState(() => _loading = false);

      final completed = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => ConsultationFormScreen(
            session: widget.session,
            patientGateway: widget.patientGateway,
            patient: widget.patient,
            visitId: visitId,
            vitals: vitals,
          ),
        ),
      );
      if (completed == true && mounted) {
        _loadTimeline();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        _showMessage('Impossible de charger les constantes de consultation.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(
              title: widget.patient.fullName,
              subtitle: 'Profil patient',
              trailing: IconButton.filled(
                onPressed: () {},
                tooltip: 'Modifier',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.medicalGreen,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.edit_rounded),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: [
                  _PatientProfileCard(
                    patient: widget.patient,
                    status: _currentStatus,
                  ),
                  const SizedBox(height: 14),
                  _PatientWorkflowStepper(
                    status: _currentStatus,
                    hasVitals:
                        _timeline.isNotEmpty && _timeline.first.vitals != null,
                  ),
                  const SizedBox(height: 14),
                  MetricStrip(
                    items: [
                      MetricStripItem(
                        value: _timeline.length.toString(),
                        label: _timeline.length > 1 ? 'visites' : 'visite',
                        color: AppColors.deepHealthBlue,
                      ),
                      MetricStripItem(
                        value: _timeline
                            .where((item) => item.consultation != null)
                            .length
                            .toString(),
                        label: 'consult.',
                        color: AppColors.medicalGreen,
                      ),
                      MetricStripItem(
                        value: widget.patient.priority == PatientPriority.urgent
                            ? '1'
                            : '0',
                        label: 'alerte',
                        color: AppColors.warning,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _SectionTitle(title: 'Actions patient'),
                  const SizedBox(height: 10),
                  _buildPatientAction(),
                  const SizedBox(height: 10),
                  (() {
                    final latestConsult = _latestConsultationWithPrescription;
                    return ActionTile(
                      icon: Icons.receipt_long_rounded,
                      title: 'Dernière Ordonnance',
                      subtitle: latestConsult != null
                          ? 'Imprimer / Voir l\'ordonnance'
                          : 'Aucune ordonnance rédigée',
                      onTap: latestConsult != null
                          ? () => _viewPrescriptionDetail(latestConsult)
                          : null,
                    );
                  })(),
                  const SizedBox(height: 18),
                  _SectionTitle(title: 'Résumé clinique'),
                  const SizedBox(height: 10),
                  _ClinicalSummary(patient: widget.patient),
                  const SizedBox(height: 18),
                  _SectionTitle(title: 'Historique'),
                  const SizedBox(height: 10),
                  if (_loading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_error != null)
                    Center(
                      child: Column(
                        children: [
                          Text(
                            _error!,
                            style: const TextStyle(color: AppColors.error),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _loadTimeline,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    )
                  else if (_timeline.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 18,
                        horizontal: 4,
                      ),
                      child: Text(
                        'Aucun historique de visite disponible.',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                    )
                  else ...[
                    for (final item in _timeline) ...[
                      _TimelineItem(
                        icon: _timelineIcon(item),
                        title: _timelineTitle(item),
                        subtitle: _timelineSubtitle(item),
                        date: _formatDate(item.arrivalAt),
                        onTap: item.consultation != null
                            ? () => _viewPrescriptionDetail(item)
                            : null,
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openVisitForm() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => PatientVisitFormScreen(
          session: widget.session,
          patientGateway: widget.patientGateway,
          patient: widget.patient,
        ),
      ),
    );
    if (created == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Widget _buildPatientAction() {
    final latestVisit = _latestVisit;
    if (!_hasActiveVisit || latestVisit == null) {
      return ActionTile(
        icon: Icons.add_box_rounded,
        title: 'Nouvelle visite',
        subtitle: 'Enregistrer une nouvelle visite (Étape 1)',
        onTap: _openVisitForm,
      );
    }

    if (latestVisit.status == PatientStatus.cashDesk) {
      final nextLabel = _statusAfterCashDesk == PatientStatus.lab
          ? 'Labo'
          : 'Sortie';
      return ActionTile(
        icon: Icons.payments_rounded,
        title: 'Valider le passage en caisse',
        subtitle: 'Encaissement puis orientation vers $nextLabel (Étape 4)',
        onTap: _completeCashDeskStep,
      );
    }

    if (latestVisit.status == PatientStatus.lab) {
      return const ActionTile(
        icon: Icons.science_rounded,
        title: 'En attente du laboratoire',
        subtitle: 'Examens et résultats à traiter au laboratoire (Étape 5)',
      );
    }

    if (latestVisit.vitals == null) {
      return ActionTile(
        icon: Icons.monitor_heart_rounded,
        title: 'Saisir les constantes',
        subtitle: 'Tension, pouls, température (Étape 2)',
        onTap: _openVitalsForm,
      );
    }

    if (latestVisit.status != PatientStatus.inConsultation) {
      return ActionTile(
        icon: Icons.play_arrow_rounded,
        title: 'Démarrer la consultation',
        subtitle: 'Fiche d\'observation & diagnostic (Étape 3)',
        onTap: _openConsultationForm,
      );
    }

    return ActionTile(
      icon: Icons.assignment_rounded,
      title: 'Rédiger la consultation',
      subtitle: 'Saisir le rapport et l\'ordonnance (Étape 3)',
      onTap: _openConsultationForm,
    );
  }

  IconData _timelineIcon(PatientTimelineItem item) {
    if (item.consultation != null) {
      return Icons.assignment_rounded;
    }
    if (item.vitals != null) {
      return Icons.monitor_heart_rounded;
    }
    if (item.targetService == 'LAB') {
      return Icons.science_rounded;
    }
    if (item.targetService == 'CASH_DESK') {
      return Icons.payments_rounded;
    }
    return Icons.login_rounded;
  }

  String _timelineTitle(PatientTimelineItem item) {
    if (item.consultation != null) {
      return 'Consultation - ${item.reason}';
    }
    if (item.vitals != null) {
      return 'Prise de constantes - ${item.reason}';
    }
    return 'Visite - ${item.reason}';
  }

  String _timelineSubtitle(PatientTimelineItem item) {
    final consultation = item.consultation;
    final vitals = item.vitals;

    if (consultation != null) {
      return 'Diagnostic : ${consultation.diagnosis}';
    }
    if (vitals != null) {
      final temp = vitals.temperature != null
          ? '${vitals.temperature}°C'
          : '--';
      final bp =
          vitals.systolicPressure != null && vitals.diastolicPressure != null
          ? '${vitals.systolicPressure}/${vitals.diastolicPressure} mmHg'
          : '--';
      return 'T°: $temp · PA: $bp';
    }
    return 'Service : ${item.targetService} · Statut : ${item.status.label}';
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final isToday =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final timeStr =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (isToday) {
      return "Auj. · $timeStr";
    }
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} · $timeStr';
  }

  PatientTimelineItem? get _latestConsultationWithPrescription {
    for (final item in _timeline) {
      if (item.consultation != null) {
        return item;
      }
    }
    return null;
  }
}

class _PatientProfileCard extends StatelessWidget {
  const _PatientProfileCard({required this.patient, required this.status});

  final PatientSummary patient;
  final PatientStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.deepHealthBlue,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepHealthBlue.withValues(alpha: 0.14),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 29,
            backgroundColor: Colors.white,
            child: Text(
              patient.initials,
              style: const TextStyle(
                color: AppColors.deepHealthBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${patient.sexAge} · ${patient.phoneNumber}',
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.76),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          PatientStatusBadge(status: status),
        ],
      ),
    );
  }
}

class _PatientWorkflowStepper extends StatelessWidget {
  const _PatientWorkflowStepper({
    required this.status,
    required this.hasVitals,
  });

  final PatientStatus status;
  final bool hasVitals;

  int get currentStep {
    if (status == PatientStatus.released) return 5;
    if (status == PatientStatus.lab) return 4;
    if (status == PatientStatus.cashDesk) return 3;
    if (status == PatientStatus.inConsultation) return 2;
    if (status == PatientStatus.waiting) {
      return hasVitals
          ? 2
          : 1; // If vitals taken, next step is consultation. Else, next step is vitals.
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
      _StepInfo('Visite', Icons.login_rounded),
      _StepInfo('Constantes', Icons.monitor_heart_rounded),
      _StepInfo('Consultation', Icons.medical_services_rounded),
      _StepInfo('Caisse', Icons.payments_rounded),
      _StepInfo('Labo', Icons.science_rounded),
      _StepInfo('Sortie', Icons.check_circle_rounded),
    ];

    final activeIndex = currentStep;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 10),
            child: Text(
              'Étape actuelle du parcours patient',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: AppColors.deepHealthBlue,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(steps.length, (index) {
              final step = steps[index];
              final isCompleted = index < activeIndex;
              final isActive = index == activeIndex;

              Color stepColor;
              if (isCompleted) {
                stepColor = AppColors.medicalGreen;
              } else if (isActive) {
                stepColor = AppColors.deepHealthBlue;
              } else {
                stepColor = Colors.grey[300]!;
              }

              return Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Left connecting line
                        Expanded(
                          child: Container(
                            height: 2,
                            color: index == 0
                                ? Colors.transparent
                                : (index <= activeIndex
                                      ? AppColors.medicalGreen
                                      : Colors.grey[200]),
                          ),
                        ),
                        // Circle Indicator
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.white
                                : (isCompleted
                                      ? AppColors.medicalGreen
                                      : Colors.grey[50]),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: stepColor,
                              width: isActive ? 2.5 : 1.5,
                            ),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: AppColors.deepHealthBlue
                                          .withValues(alpha: 0.15),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Icon(
                            isCompleted ? Icons.check_rounded : step.icon,
                            size: 14,
                            color: isCompleted
                                ? Colors.white
                                : (isActive
                                      ? AppColors.deepHealthBlue
                                      : Colors.grey[400]),
                          ),
                        ),
                        // Right connecting line
                        Expanded(
                          child: Container(
                            height: 2,
                            color: index == steps.length - 1
                                ? Colors.transparent
                                : (index < activeIndex
                                      ? AppColors.medicalGreen
                                      : Colors.grey[200]),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      step.title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: isActive
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isActive
                            ? AppColors.deepHealthBlue
                            : (isCompleted
                                  ? AppColors.textPrimary
                                  : Colors.grey[500]),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _StepInfo {
  const _StepInfo(this.title, this.icon);
  final String title;
  final IconData icon;
}

class _ClinicalSummary extends StatelessWidget {
  const _ClinicalSummary({required this.patient});

  final PatientSummary patient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.40)),
      ),
      child: Column(
        children: [
          _InfoRow(label: "Motif d'arrivée", value: patient.reason),
          const SizedBox(height: 10),
          _InfoRow(label: 'Dernière visite', value: patient.lastVisit),
          const SizedBox(height: 10),
          _InfoRow(label: 'Priorité', value: patient.priority.label),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.fade,
            softWrap: false,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.date,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String date;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ActionTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      trailing: Text(
        date,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
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

class _DrugDetailTag extends StatelessWidget {
  const _DrugDetailTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.deepHealthBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.deepHealthBlue,
        ),
      ),
    );
  }
}
