import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../consultations/domain/consultation_decision.dart';
import '../../consultations/domain/prescription.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/presentation/widgets/action_tile.dart';
import '../../../shared/presentation/widgets/metric_strip.dart';
import '../../../shared/presentation/widgets/page_header.dart';
import '../../auth/domain/auth_session.dart';
import '../../cashdesk/domain/invoice_preview.dart';
import '../../cashdesk/domain/invoice.dart';
import '../../cashdesk/presentation/cashdesk_payment_sheet.dart';
import '../data/patient_gateway.dart';
import '../domain/patient_summary.dart';
import '../domain/patient_timeline_item.dart';
import '../domain/vitals_summary.dart';
import '../../consultations/presentation/consultation_form_screen.dart';
import '../../consultations/presentation/lab_results_form_screen.dart';
import '../../consultations/presentation/vitals_form_screen.dart';
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
  bool _changed = false;
  bool _loading = true;
  String? _error;
  InvoicePreview? _invoicePreview;

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

      InvoicePreview? invoicePreview;
      if (items.isNotEmpty && items.first.status == PatientStatus.cashDesk) {
        try {
          invoicePreview = await widget.patientGateway.getInvoicePreview(
            session: widget.session,
            visitId: items.first.visitId,
          );
        } catch (_) {}
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _timeline = items;
        _invoicePreview = invoicePreview;
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

  void _showVisitDetailSheet(BuildContext context, PatientTimelineItem item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.85,
          child: _VisitDetailSheet(
            session: widget.session,
            patientGateway: widget.patientGateway,
            patient: widget.patient,
            item: item,
          ),
        );
      },
    );
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

    final navigator = Navigator.of(context);

    final payload = await showCashDeskPaymentSheet(
      context,
      patientName: widget.patient.fullName,
      targetLabel: _statusAfterCashDesk == PatientStatus.lab
          ? 'vers labo'
          : 'vers sortie',
      patientGateway: widget.patientGateway,
      session: widget.session,
      visitId: latestVisit.visitId,
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
        setState(() {
          _changed = true;
        });
        await _loadTimeline();
      }

      final relativeUrl = '/visits/${latestVisit.visitId}/invoice/pdf';
      final baseUrlString = widget.patientGateway is BackendPatientGateway
          ? (widget.patientGateway as BackendPatientGateway).apiClient.baseUrl
          : "http://localhost:8080/api/v1";
      final fullUrl = '$baseUrlString$relativeUrl';

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Paiement validé !'),
            content: const Text(
              'Le reçu de paiement a été généré avec succès. Souhaitez-vous le prévisualiser et l\'imprimer ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Plus tard'),
              ),
              FilledButton.icon(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.of(dialogContext).pop();
                  final url = Uri.parse(fullUrl);
                  try {
                    final success = await launchUrl(
                      url,
                      mode: LaunchMode.externalApplication,
                    );
                    if (!success) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Impossible d\'ouvrir le PDF.'),
                        ),
                      );
                    }
                  } catch (_) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Impossible d\'ouvrir le PDF.'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.print_rounded),
                label: const Text('Imprimer'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.medicalGreen,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      );

      navigator.pop(_changed);
    } catch (_) {
      _showMessage('Impossible de valider le passage en caisse.');
    }
  }

  Future<void> _returnToConsultationStep() async {
    final latestVisit = _latestVisit;
    if (latestVisit == null) {
      _showMessage('Visite non synchronisée avec le serveur.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Revenir à la consultation ?'),
          content: const Text(
            'Le patient quittera la caisse pour permettre la correction de la décision médicale avant encaissement.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.undo_rounded),
              label: const Text('Revenir'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }

    try {
      await widget.patientGateway.changeVisitStatus(
        session: widget.session,
        visitId: latestVisit.visitId,
        status: PatientStatus.inConsultation,
      );
      if (mounted) {
        setState(() {
          _changed = true;
        });
        await _loadTimeline();
        _showMessage('Patient replacé en consultation.');
      }
    } catch (_) {
      _showMessage('Impossible de revenir à la consultation.');
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
      setState(() {
        _changed = true;
      });
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
        setState(() {
          _changed = true;
        });
        _loadTimeline();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        _showMessage('Impossible de charger les constantes de consultation.');
      }
    }
  }

  Future<void> _openLabResultsForm() async {
    if (_timeline.isEmpty) return;
    final latestItem = _timeline.first;
    final visitId = latestItem.visitId;

    final completed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => LabResultsFormScreen(
          session: widget.session,
          patientGateway: widget.patientGateway,
          patient: widget.patient,
          visitId: visitId,
        ),
      ),
    );
    if (completed == true && mounted) {
      setState(() {
        _changed = true;
      });
      await _loadTimeline();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
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
                          _timeline.isNotEmpty &&
                          _timeline.first.vitals != null,
                      onStepTapped: _onStepTapped,
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
                          value:
                              widget.patient.priority == PatientPriority.urgent
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
                    ..._buildPatientActions(),
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
                            ? () =>
                                  _showVisitDetailSheet(context, latestConsult)
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
                          documents: _timelineDocuments(item),
                          onTap: () => _showVisitDetailSheet(context, item),
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
      // Stay on the detail screen and reload the timeline
      // instead of popping back to the patient list.
      setState(() {
        _changed = true;
      });
      _loadTimeline();
    }
  }

  /// Handle a tap on a workflow stepper step.
  void _onStepTapped(int stepIndex) {
    switch (stepIndex) {
      case 0:
        // Step 0: Visite — only if no active visit
        if (!_hasActiveVisit) _openVisitForm();
        break;
      case 1:
        // Step 1: Constantes — open vitals form (create or edit)
        if (_hasActiveVisit) _openVitalsForm();
        break;
      case 2:
        // Step 2: Consultation — open consultation form
        if (_hasActiveVisit && _latestVisit?.vitals != null) {
          _openConsultationForm();
        }
        break;
      case 3:
        // Step 3: Caisse
        if (_latestVisit?.status == PatientStatus.cashDesk) {
          _completeCashDeskStep();
        }
        break;
      case 4:
        if (_latestVisit?.status == PatientStatus.lab) {
          _openLabResultsForm();
        }
        break;
      default:
        break;
    }
  }

  /// Builds a list of action tiles: the current step action PLUS
  /// shortcuts to go back to previous steps.
  List<Widget> _buildPatientActions() {
    final latestVisit = _latestVisit;
    final actions = <Widget>[];

    // ── No active visit: only show "new visit" ──
    if (!_hasActiveVisit || latestVisit == null) {
      actions.add(
        ActionTile(
          icon: Icons.add_box_rounded,
          title: 'Nouvelle visite',
          subtitle: 'Enregistrer une nouvelle visite (Étape 1)',
          onTap: _openVisitForm,
        ),
      );
      return actions;
    }

    // ── Current-step action (primary) ──
    if (latestVisit.status == PatientStatus.cashDesk) {
      final nextLabel = _statusAfterCashDesk == PatientStatus.lab
          ? 'Labo'
          : 'Sortie';
      final amountSuffix = _invoicePreview != null
          ? ' - ${_invoicePreview!.netAmount.toInt()} Frs'
          : '';
      actions.add(
        ActionTile(
          icon: Icons.payments_rounded,
          title: 'Valider le passage en caisse$amountSuffix',
          subtitle: 'Encaissement puis orientation vers $nextLabel (Étape 4)',
          onTap: _completeCashDeskStep,
        ),
      );
      actions.add(const SizedBox(height: 6));
      actions.add(
        ActionTile(
          key: const ValueKey('return-to-consultation-action'),
          icon: Icons.undo_rounded,
          title: 'Revenir en consultation',
          subtitle: 'Corriger la décision médicale avant encaissement',
          onTap: _returnToConsultationStep,
        ),
      );
    } else if (latestVisit.status == PatientStatus.lab) {
      actions.add(
        ActionTile(
          icon: Icons.science_rounded,
          title: 'Saisir les résultats labo',
          subtitle: 'Valider les examens puis retour consultation (Étape 5)',
          onTap: _openLabResultsForm,
        ),
      );
    } else if (latestVisit.vitals == null) {
      actions.add(
        ActionTile(
          icon: Icons.monitor_heart_rounded,
          title: 'Saisir les constantes',
          subtitle: 'Tension, pouls, température (Étape 2)',
          onTap: _openVitalsForm,
        ),
      );
    } else if (latestVisit.status != PatientStatus.inConsultation) {
      actions.add(
        ActionTile(
          icon: Icons.play_arrow_rounded,
          title: 'Démarrer la consultation',
          subtitle: 'Fiche d\'observation & diagnostic (Étape 3)',
          onTap: _openConsultationForm,
        ),
      );
    } else {
      actions.add(
        ActionTile(
          icon: Icons.assignment_rounded,
          title: 'Rédiger la consultation',
          subtitle: 'Saisir le rapport et l\'ordonnance (Étape 3)',
          onTap: _openConsultationForm,
        ),
      );
    }

    // ── Back-step actions (secondary) — allow returning to previous steps ──
    // Show "Modifier les constantes" if vitals exist and we're past that step
    if (latestVisit.vitals != null &&
        latestVisit.status != PatientStatus.waiting) {
      actions.add(const SizedBox(height: 6));
      actions.add(
        ActionTile(
          icon: Icons.edit_note_rounded,
          title: 'Modifier les constantes',
          subtitle: 'Revenir à l\'étape 2 pour corriger les constantes',
          onTap: _openVitalsForm,
        ),
      );
    }

    // Show "Modifier la consultation" if we're past consultation
    // (at cashDesk or lab) and a consultation exists
    if (latestVisit.consultation != null &&
        (latestVisit.status == PatientStatus.cashDesk ||
            latestVisit.status == PatientStatus.lab)) {
      actions.add(const SizedBox(height: 6));
      actions.add(
        ActionTile(
          icon: Icons.edit_document,
          title: 'Modifier la consultation',
          subtitle: 'Revenir à l\'étape 3 pour corriger la consultation',
          onTap: _openConsultationForm,
        ),
      );
    }

    return actions;
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
      final diagnosis = consultation.diagnosis.trim();
      return diagnosis.isEmpty
          ? 'Diagnostic non renseigné'
          : 'Diagnostic : $diagnosis';
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

  List<_TimelineDocument> _timelineDocuments(PatientTimelineItem item) {
    return [
      if (item.consultation?.hasPrescription == true)
        const _TimelineDocument(
          label: 'Ordonnance',
          icon: Icons.description_rounded,
          color: AppColors.medicalGreen,
        ),
      if (item.labResult != null)
        const _TimelineDocument(
          label: 'Résultat labo',
          icon: Icons.science_rounded,
          color: AppColors.info,
        ),
      if (_hasInvoiceDocument(item))
        const _TimelineDocument(
          label: 'Reçu',
          icon: Icons.receipt_long_rounded,
          color: AppColors.warning,
        ),
    ];
  }

  bool _hasInvoiceDocument(PatientTimelineItem item) {
    return item.status == PatientStatus.released ||
        item.status == PatientStatus.lab ||
        item.status == PatientStatus.cashDesk;
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
    this.onStepTapped,
  });

  final PatientStatus status;
  final bool hasVitals;
  final void Function(int stepIndex)? onStepTapped;

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

              // Steps that are completed or active can be tapped
              final isTappable =
                  (isCompleted || isActive) && onStepTapped != null;

              return Expanded(
                child: GestureDetector(
                  onTap: isTappable ? () => onStepTapped!(index) : null,
                  behavior: HitTestBehavior.opaque,
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
                          // Underline tappable steps to hint interactivity
                          decoration: isTappable
                              ? TextDecoration.underline
                              : TextDecoration.none,
                          decorationColor: isActive
                              ? AppColors.deepHealthBlue
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
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
    required this.documents,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String date;
  final List<_TimelineDocument> documents;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.40)),
            boxShadow: [
              BoxShadow(
                color: AppColors.deepHealthBlue.withValues(alpha: 0.035),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TimelineLeadingIcon(icon: icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final titleWidget = Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                height: 1.12,
                              ),
                        );
                        final dateWidget = Text(
                          date,
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                          softWrap: false,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                                height: 1.12,
                              ),
                        );

                        if (constraints.maxWidth < 270) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              titleWidget,
                              const SizedBox(height: 3),
                              dateWidget,
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: titleWidget),
                            const SizedBox(width: 8),
                            dateWidget,
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.18,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (documents.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final document in documents)
                            _TimelineDocumentChip(
                              document: document,
                              onTap: onTap,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineLeadingIcon extends StatelessWidget {
  const _TimelineLeadingIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.medicalGreen.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: AppColors.medicalGreen, size: 20),
    );
  }
}

class _TimelineDocument {
  const _TimelineDocument({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}

class _TimelineDocumentChip extends StatelessWidget {
  const _TimelineDocumentChip({required this.document, this.onTap});

  final _TimelineDocument document;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: 'Pièce jointe ${document.label}',
      child: Material(
        color: document.color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            constraints: const BoxConstraints(minHeight: 28),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: document.color.withValues(alpha: 0.22)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(document.icon, size: 15, color: document.color),
                const SizedBox(width: 5),
                Text(
                  document.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: document.color,
                    fontWeight: FontWeight.w700,
                    height: 1.05,
                  ),
                ),
              ],
            ),
          ),
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

class _VisitDetailSheet extends StatefulWidget {
  const _VisitDetailSheet({
    required this.session,
    required this.patientGateway,
    required this.patient,
    required this.item,
  });

  final AuthSession session;
  final PatientGateway patientGateway;
  final PatientSummary patient;
  final PatientTimelineItem item;

  @override
  State<_VisitDetailSheet> createState() => _VisitDetailSheetState();
}

class _VisitDetailSheetState extends State<_VisitDetailSheet> {
  Prescription? _prescription;
  bool _loadingPrescription = false;
  Invoice? _invoice;
  bool _loadingInvoice = false;

  @override
  void initState() {
    super.initState();
    if (widget.item.consultation?.hasPrescription == true) {
      _loadPrescription();
    }
    final hasInvoice =
        widget.item.status == PatientStatus.released ||
        widget.item.status == PatientStatus.lab ||
        widget.item.status == PatientStatus.cashDesk;
    if (hasInvoice) {
      _loadInvoice();
    }
  }

  Future<void> _loadInvoice() async {
    setState(() => _loadingInvoice = true);
    try {
      final list = await widget.patientGateway.getInvoices(
        session: widget.session,
        visitId: widget.item.visitId,
      );
      if (list.isNotEmpty && mounted) {
        setState(() {
          _invoice = list.first;
          _loadingInvoice = false;
        });
      } else {
        if (mounted) {
          setState(() => _loadingInvoice = false);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingInvoice = false);
      }
    }
  }

  Future<void> _loadPrescription() async {
    setState(() => _loadingPrescription = true);
    try {
      final prescription = await widget.patientGateway.getPrescription(
        session: widget.session,
        consultationId: widget.item.consultation!.id,
      );
      if (mounted) {
        setState(() {
          _prescription = prescription;
          _loadingPrescription = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingPrescription = false);
      }
    }
  }

  Future<void> _openPdf(String relativeUrl) async {
    final baseUrl = widget.patientGateway is BackendPatientGateway
        ? (widget.patientGateway as BackendPatientGateway).apiClient.baseUrl
        : "http://localhost:8080/api/v1";

    var fullUrl = relativeUrl;
    if (!relativeUrl.startsWith('http://') &&
        !relativeUrl.startsWith('https://')) {
      if (relativeUrl.startsWith('/api/v1/')) {
        if (baseUrl.endsWith('/api/v1')) {
          fullUrl = '$baseUrl${relativeUrl.substring(7)}';
        } else {
          fullUrl = '$baseUrl$relativeUrl';
        }
      } else {
        if (!relativeUrl.startsWith('/')) {
          relativeUrl = '/$relativeUrl';
        }
        fullUrl = '$baseUrl$relativeUrl';
      }
    }

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
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final vitals = item.vitals;
    final consultation = item.consultation;
    final labResult = item.labResult;

    final hasInvoice =
        item.status == PatientStatus.released ||
        item.status == PatientStatus.lab ||
        item.status == PatientStatus.cashDesk;

    return Container(
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Visite du ${_formatDate(item.arrivalAt)}',
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepHealthBlue,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Motif : ${item.reason}',
                        style: TextStyle(
                          fontSize: 12.5,
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
                if (vitals != null) ...[
                  _buildSectionHeader(
                    'Constantes médicales',
                    Icons.monitor_heart_rounded,
                  ),
                  const SizedBox(height: 8),
                  _buildVitalsCard(vitals),
                  const SizedBox(height: 18),
                ],
                if (consultation != null) ...[
                  _buildSectionHeader(
                    'Consultation médicale',
                    Icons.assignment_rounded,
                  ),
                  const SizedBox(height: 8),
                  _buildConsultationCard(consultation),
                  const SizedBox(height: 18),
                ],
                if (labResult != null) ...[
                  _buildSectionHeader(
                    'Résultats de laboratoire',
                    Icons.science_rounded,
                  ),
                  const SizedBox(height: 8),
                  _buildLabResultsCard(labResult),
                  const SizedBox(height: 18),
                ],
                if (hasInvoice) ...[
                  _buildSectionHeader(
                    'Facturation & Encaissement',
                    Icons.payments_rounded,
                  ),
                  const SizedBox(height: 8),
                  _buildInvoiceCard(item.visitId),
                  const SizedBox(height: 18),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.deepHealthBlue, size: 19),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.bold,
            color: AppColors.deepHealthBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildVitalsCard(VitalsSummary vitals) {
    final temp = vitals.temperature != null ? '${vitals.temperature}°C' : '--';
    final bp =
        vitals.systolicPressure != null && vitals.diastolicPressure != null
        ? '${vitals.systolicPressure}/${vitals.diastolicPressure} mmHg'
        : '--';
    final pulse = vitals.pulse != null ? '${vitals.pulse} bpm' : '--';
    final weight = vitals.weight != null ? '${vitals.weight} kg' : '--';
    final height = vitals.height != null ? '${vitals.height} cm' : '--';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightBackground.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildVitalItem('Température', temp),
              _buildVitalItem('Tension Artérielle', bp),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildVitalItem('Pouls', pulse),
              _buildVitalItem('Poids / Taille', '$weight / $height'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVitalItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationCard(PatientConsultationSummary consultation) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightBackground.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextInfo('Symptômes', consultation.symptoms),
          const SizedBox(height: 10),
          _buildTextInfo('Examen Clinique', consultation.clinicalExam),
          const SizedBox(height: 10),
          _buildTextInfo('Diagnostic final', consultation.diagnosis),
          if (consultation.advice != null &&
              consultation.advice!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildTextInfo('Conduite à tenir / Conseils', consultation.advice!),
          ],
          if (consultation.hasPrescription) ...[
            const Divider(height: 20),
            const Text(
              'Ordonnance médicale',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.deepHealthBlue,
              ),
            ),
            const SizedBox(height: 8),
            if (_loadingPrescription)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_prescription != null) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _prescription!.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.circle,
                          size: 6,
                          color: AppColors.medicalGreen,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${item.drugName} - ${item.dosage ?? ""} (${item.form ?? ""})',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () {
                  final pdfUrl =
                      _prescription!.pdfUrl ??
                      '/consultations/${consultation.id}/prescription/pdf';
                  _openPdf(pdfUrl);
                },
                icon: const Icon(Icons.print_rounded, size: 16),
                label: const Text('Imprimer l\'ordonnance'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.medicalGreen,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(38),
                ),
              ),
            ] else
              const Text(
                'Impossible de charger l\'ordonnance.',
                style: TextStyle(fontSize: 12, color: AppColors.error),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.deepHealthBlue,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value.isEmpty ? '—' : value,
          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildLabResultsCard(PatientLabResultSummary labResult) {
    final badgeColor = labResult.isNormal
        ? AppColors.medicalGreen
        : AppColors.error;
    final badgeText = labResult.isNormal
        ? 'Résultats normaux'
        : 'Résultats anormaux / Pathologie';
    final examType = _compactLabExamType(labResult.examType);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightBackground.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Type d\'examen',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.deepHealthBlue,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      examType,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.20)),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextInfo('Analyses / Résultats saisis', labResult.results),
          if (labResult.observations != null &&
              labResult.observations!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildTextInfo(
              'Observations du laboratoire',
              labResult.observations!,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Date prélèvement : ${_formatDateOnly(labResult.sampleDate)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'N° Dossier LAB : ${labResult.dossierNumber ?? "—"}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () =>
                _openPdf('/visits/${widget.item.visitId}/lab-results/pdf'),
            icon: const Icon(Icons.print_rounded, size: 16),
            label: const Text('Imprimer les résultats'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.deepHealthBlue,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(38),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(String visitId) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightBackground.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.medicalGreen,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Paiement encaissé avec succès',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          if (_loadingInvoice) ...[
            const SizedBox(height: 12),
            const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ] else if (_invoice != null) ...[
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'N° Reçu : ${_invoice!.invoiceNumber}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.deepHealthBlue,
                  ),
                ),
                Text(
                  _formatDate(_invoice!.createdAt),
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._invoice!.items.map((line) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${line.label} (x${line.quantity})',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '${line.price.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Montant total payé :',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${_invoice!.paidAmount.toStringAsFixed(0)} FCFA',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.medicalGreen,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _openPdf('/visits/$visitId/invoice/pdf'),
            icon: const Icon(Icons.receipt_long_rounded, size: 16),
            label: const Text('Visualiser & Imprimer le reçu'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.premiumGold,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(38),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final timeStr =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} à $timeStr';
  }

  String _formatDateOnly(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  String _compactLabExamType(String value) {
    final separatorIndex = value.indexOf(' - ');
    if (separatorIndex <= 0) {
      return value;
    }
    return value.substring(0, separatorIndex).trim();
  }
}
