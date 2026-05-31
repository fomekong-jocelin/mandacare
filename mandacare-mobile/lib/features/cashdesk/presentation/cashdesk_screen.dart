import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/api/api_client.dart';
import '../../../shared/presentation/document_preview_share_screen.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/presentation/layout/adaptive_layout.dart';
import '../../../shared/presentation/widgets/feature_header.dart';
import '../../activity/data/activity_history_gateway.dart';
import '../../activity/domain/activity_history_item.dart';
import '../../activity/presentation/activity_history_widgets.dart';
import '../../auth/domain/auth_session.dart';
import '../../consultations/domain/consultation_decision.dart';
import '../../patients/data/patient_gateway.dart';
import '../../patients/domain/patient_summary.dart';
import '../../patients/presentation/patient_detail_screen.dart';
import '../domain/invoice_preview.dart';
import 'cashdesk_payment_sheet.dart';

part 'widgets/cashdesk_widgets.dart';

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
  List<CashDeskHistoryItem> _history = const [];
  late ActivityHistoryGateway _activityGateway;
  int _selectedSegment = 0;
  ActivityHistoryPeriod _historyPeriod = ActivityHistoryPeriod.thirtyDays;
  String _historyStatus = activityAllStatuses;
  bool _loading = true;
  bool _loadingHistory = false;
  String? _error;
  String? _historyError;
  String? _completingVisitId;

  @override
  void initState() {
    super.initState();
    _activityGateway = activityHistoryGatewayFor(widget.patientGateway);
    _loadCashDeskQueue();
  }

  @override
  void didUpdateWidget(covariant CashDeskScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshRequestId != oldWidget.refreshRequestId) {
      _activityGateway = activityHistoryGatewayFor(widget.patientGateway);
      _loadCashDeskQueue(showLoader: false);
      if (_selectedSegment == 1) {
        _loadHistory();
      }
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

  Future<void> _loadHistory() async {
    setState(() {
      _loadingHistory = true;
      _historyError = null;
    });
    try {
      final history = await _activityGateway.listCashDesk(
        session: widget.session,
        period: _historyPeriod,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _history = history;
        _loadingHistory = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _historyError = "Impossible de charger l'historique.";
        _loadingHistory = false;
      });
    }
  }

  void _selectSegment(int value) {
    setState(() => _selectedSegment = value);
    if (value == 1 && _history.isEmpty && !_loadingHistory) {
      _loadHistory();
    }
  }

  void _changeHistoryPeriod(ActivityHistoryPeriod period) {
    setState(() {
      _historyPeriod = period;
      _historyStatus = activityAllStatuses;
    });
    _loadHistory();
  }

  void _changeHistoryStatus(String status) {
    setState(() => _historyStatus = status);
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
      double? netAmount;
      final visitId = patient.latestVisitId;
      if (visitId != null) {
        try {
          final InvoicePreview preview = await widget.patientGateway
              .getInvoicePreview(session: widget.session, visitId: visitId);
          netAmount = preview.netAmount;
        } catch (_) {}
      }
      return _CashDeskPatient(
        patient: patient,
        decision: timeline.isEmpty
            ? null
            : timeline.first.consultation?.decision,
        netAmount: netAmount,
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
      patientGateway: widget.patientGateway,
      session: widget.session,
      visitId: visitId,
    );
    if (payload == null) {
      return;
    }

    setState(() => _completingVisitId = visitId);
    try {
      String? phone;
      try {
        final matchingPatient = _patients.firstWhere(
          (p) => p.patient.latestVisitId == visitId,
        );
        phone = matchingPatient.patient.phoneNumber;
      } catch (_) {}

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

      final relativeUrl = '/visits/$visitId/invoice/pdf';
      final baseUrlString = widget.patientGateway is BackendPatientGateway
          ? (widget.patientGateway as BackendPatientGateway).apiClient.baseUrl
          : "http://localhost:8080/api/v1";
      final apiClient = widget.patientGateway is BackendPatientGateway
          ? (widget.patientGateway as BackendPatientGateway).apiClient
          : ApiClient(baseUrl: baseUrlString);

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Paiement validé !'),
            content: const Text(
              'Le reçu de paiement a été généré avec succès. Souhaitez-vous le prévisualiser, le télécharger ou le partager ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Plus tard'),
              ),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => DocumentPreviewShareScreen(
                        pdfUrl: relativeUrl,
                        title: 'Reçu de paiement',
                        session: widget.session,
                        apiClient: apiClient,
                        entityId: visitId,
                        entityType: 'INVOICE',
                        phoneNumber: phone,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.preview_rounded),
                label: const Text('Prévisualiser'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.medicalGreen,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
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
                        ActivitySegmentedHeader(
                          selectedIndex: _selectedSegment,
                          onSelectionChanged: _selectSegment,
                        ),
                        const SizedBox(height: 14),
                        if (_selectedSegment == 1) ...[
                          CashDeskHistoryList(
                            items: _history,
                            loading: _loadingHistory,
                            error: _historyError,
                            period: _historyPeriod,
                            statusFilter: _historyStatus,
                            onPeriodChanged: _changeHistoryPeriod,
                            onStatusChanged: _changeHistoryStatus,
                            onRetry: _loadHistory,
                          ),
                        ] else ...[
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
