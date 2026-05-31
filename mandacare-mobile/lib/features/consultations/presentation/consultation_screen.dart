import 'package:flutter/material.dart';

import '../../../app/api/api_client.dart';
import '../../../app/api/api_exception.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/presentation/layout/adaptive_layout.dart';
import '../../../shared/presentation/widgets/feature_header.dart';
import '../../../shared/presentation/widgets/metric_strip.dart';
import '../../activity/data/activity_history_gateway.dart';
import '../../activity/domain/activity_history_item.dart';
import '../../activity/presentation/activity_history_widgets.dart';
import '../../auth/domain/auth_session.dart';
import '../../patients/data/patient_gateway.dart';
import '../../patients/domain/patient_summary.dart';
import '../../patients/domain/vitals_summary.dart';
import 'consultation_form_screen.dart';
import 'widgets/consultation_overview_widgets.dart';
import 'widgets/latest_vitals_card.dart';

class ConsultationScreen extends StatefulWidget {
  const ConsultationScreen({
    required this.session,
    required this.patientGateway,
    required this.refreshRequestId,
    super.key,
  });

  final AuthSession session;
  final PatientGateway patientGateway;
  final int refreshRequestId;

  @override
  State<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends State<ConsultationScreen> {
  final List<PatientSummary> _patients = [];
  final List<ConsultationHistoryItem> _history = [];

  late ActivityHistoryGateway _activityGateway;
  PatientSummary? _selectedPatient;
  VitalsSummary? _selectedVitals;
  String? _screenError;
  String? _vitalsError;
  String? _historyError;
  int _selectedSegment = 0;
  ActivityHistoryPeriod _historyPeriod = ActivityHistoryPeriod.thirtyDays;
  String _historyStatus = activityAllStatuses;
  bool _loadingPatients = true;
  bool _loadingVitals = false;
  bool _loadingHistory = false;
  int _vitalsRequestId = 0;

  @override
  void initState() {
    super.initState();
    _activityGateway = activityHistoryGatewayFor(widget.patientGateway);
    _loadConsultations();
  }

  @override
  void didUpdateWidget(covariant ConsultationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session ||
        oldWidget.patientGateway != widget.patientGateway ||
        oldWidget.refreshRequestId != widget.refreshRequestId) {
      _activityGateway = activityHistoryGatewayFor(widget.patientGateway);
      _loadConsultations();
      if (_selectedSegment == 1) {
        _loadHistory();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          FeatureHeader(
            title: 'Consultations',
            subtitle: 'Actes du jour et priorités',
            actionIcon: Icons.refresh_rounded,
            actionTooltip: 'Actualiser les consultations',
            onActionPressed: _loadConsultations,
          ),
          Expanded(child: _buildBody(context)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loadingPatients) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_screenError != null) {
      return LoadErrorState(
        message: _screenError!,
        onRetry: _loadConsultations,
      );
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            16,
            14,
            16,
            AdaptiveLayout.bottomContentPadding(context),
          ),
          sliver: SliverList.list(children: _contentItems()),
        ),
      ],
    );
  }

  List<Widget> _contentItems() {
    final selectedPatient = _selectedPatient;
    final header = ActivitySegmentedHeader(
      selectedIndex: _selectedSegment,
      onSelectionChanged: _selectSegment,
    );

    if (_selectedSegment == 1) {
      return [
        header,
        const SizedBox(height: 14),
        ConsultationHistoryList(
          items: _history,
          loading: _loadingHistory,
          error: _historyError,
          period: _historyPeriod,
          statusFilter: _historyStatus,
          session: widget.session,
          apiClient: _documentApiClient,
          onPeriodChanged: _changeHistoryPeriod,
          onStatusChanged: _changeHistoryStatus,
          onRetry: _loadHistory,
        ),
      ];
    }

    return [
      header,
      const SizedBox(height: 14),
      MetricStrip(
        items: [
          MetricStripItem(
            value: _patients.length.toString(),
            label: 'en cours',
            color: AppColors.medicalGreen,
          ),
          MetricStripItem(
            value: _urgentCount.toString(),
            label: 'urgentes',
            color: AppColors.warning,
          ),
          MetricStripItem(
            value: selectedPatient == null ? '0' : '1',
            label: 'sélection',
            color: AppColors.deepHealthBlue,
          ),
        ],
      ),
      const SizedBox(height: 14),
      if (selectedPatient == null)
        const EmptyConsultationCard()
      else ...[
        CurrentConsultationCard(patient: selectedPatient),
        const SizedBox(height: 12),
        FilledButton.icon(
          key: const ValueKey('open-consultation-form-button'),
          onPressed: () => _openConsultationForm(selectedPatient),
          icon: const Icon(Icons.edit_note_rounded),
          label: const Text('Rédiger la consultation'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        ),
        const SizedBox(height: 14),
        LatestVitalsCard(
          vitals: _selectedVitals,
          isLoading: _loadingVitals,
          errorMessage: _vitalsError,
        ),
        const SizedBox(height: 18),
        const _SectionTitle(title: 'Patients en consultation'),
        const SizedBox(height: 10),
        for (final patient in _patients) ...[
          ConsultationTile(
            patient: patient,
            selected: _isSamePatient(patient, selectedPatient),
            onTap: () => _selectPatient(patient),
          ),
          const SizedBox(height: 10),
        ],
      ],
    ];
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

  Future<void> _loadConsultations() async {
    setState(() {
      _loadingPatients = true;
      _screenError = null;
    });

    try {
      final queue = await widget.patientGateway.listTodayQueue(
        session: widget.session,
        status: PatientStatus.inConsultation,
        limit: 20,
      );
      final consultations = queue.toList(growable: false);
      final selectedPatient = _resolvedSelection(consultations);

      if (!mounted) {
        return;
      }
      setState(() {
        _patients
          ..clear()
          ..addAll(consultations);
        _selectedPatient = selectedPatient;
        _selectedVitals = null;
        _vitalsError = null;
        _loadingPatients = false;
      });

      await _loadVitalsFor(selectedPatient);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _patients.clear();
        _selectedPatient = null;
        _selectedVitals = null;
        _vitalsError = null;
        _screenError = _friendlyError(error);
        _loadingPatients = false;
      });
    }
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loadingHistory = true;
      _historyError = null;
    });
    try {
      final history = await _activityGateway.listConsultations(
        session: widget.session,
        period: _historyPeriod,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _history
          ..clear()
          ..addAll(history);
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

  Future<void> _selectPatient(PatientSummary patient) async {
    if (_isSamePatient(patient, _selectedPatient)) {
      return;
    }

    setState(() {
      _selectedPatient = patient;
      _selectedVitals = null;
      _vitalsError = null;
    });
    await _loadVitalsFor(patient);
  }

  Future<void> _openConsultationForm(PatientSummary patient) async {
    final visitId = patient.latestVisitId;
    if (visitId == null) {
      _showMessage('Visite non synchronisée avec le serveur.');
      return;
    }

    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ConsultationFormScreen(
          session: widget.session,
          patientGateway: widget.patientGateway,
          patient: patient,
          visitId: visitId,
          vitals: _selectedVitals,
        ),
      ),
    );
    if (!mounted || saved != true) {
      return;
    }
    await _loadConsultations();
  }

  Future<void> _loadVitalsFor(PatientSummary? patient) async {
    final requestId = ++_vitalsRequestId;
    final visitId = patient?.latestVisitId;
    if (visitId == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingVitals = false;
        _selectedVitals = null;
        _vitalsError = 'Visite non synchronisée avec le serveur.';
      });
      return;
    }

    setState(() {
      _loadingVitals = true;
      _vitalsError = null;
    });

    try {
      final vitals = await widget.patientGateway.getLatestVitals(
        session: widget.session,
        visitId: visitId,
      );
      if (!mounted || requestId != _vitalsRequestId) {
        return;
      }
      setState(() {
        _selectedVitals = vitals;
        _loadingVitals = false;
      });
    } catch (error) {
      if (!mounted || requestId != _vitalsRequestId) {
        return;
      }
      setState(() {
        _selectedVitals = null;
        _vitalsError = _vitalsErrorMessage(error);
        _loadingVitals = false;
      });
    }
  }

  PatientSummary? _resolvedSelection(List<PatientSummary> consultations) {
    final currentSelection = _selectedPatient;
    if (currentSelection != null) {
      for (final patient in consultations) {
        if (_isSamePatient(patient, currentSelection)) {
          return patient;
        }
      }
    }
    return consultations.isEmpty ? null : consultations.first;
  }

  int get _urgentCount {
    return _patients
        .where((patient) => patient.priority == PatientPriority.urgent)
        .length;
  }

  ApiClient get _documentApiClient {
    if (widget.patientGateway is BackendPatientGateway) {
      return (widget.patientGateway as BackendPatientGateway).apiClient;
    }
    return ApiClient(baseUrl: 'http://localhost:8080/api/v1');
  }

  bool _isSamePatient(PatientSummary? left, PatientSummary? right) {
    if (left == null || right == null) {
      return false;
    }
    if (left.latestVisitId != null && right.latestVisitId != null) {
      return left.latestVisitId == right.latestVisitId;
    }
    if (left.id != null && right.id != null) {
      return left.id == right.id;
    }
    return left.fullName == right.fullName;
  }

  String _friendlyError(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    return 'Consultations indisponibles pour le moment.';
  }

  String _vitalsErrorMessage(Object error) {
    if (error is ApiException && error.statusCode == 404) {
      return 'Aucune constante enregistrée pour cette visite.';
    }
    return _friendlyError(error);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
