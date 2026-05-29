import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/presentation/layout/adaptive_layout.dart';
import '../../auth/domain/auth_session.dart';
import '../data/patient_gateway.dart';
import '../domain/patient_summary.dart';
import 'patient_filter.dart';
import 'patient_detail_screen.dart';
import 'patient_form_screen.dart';
import 'widgets/patient_card.dart';
import 'widgets/patient_filter_bar.dart';
import 'widgets/patient_list_header.dart';
import 'widgets/patient_stats_strip.dart';

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({
    required this.session,
    required this.patientGateway,
    this.requestedFilter = PatientFilter.all,
    this.filterRequestId = 0,
    this.onQueueChanged,
    super.key,
  });

  final AuthSession session;
  final PatientGateway patientGateway;
  final PatientFilter requestedFilter;
  final int filterRequestId;
  final VoidCallback? onQueueChanged;

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  final _searchController = TextEditingController();
  List<PatientSummary> _patients = const [];
  PatientFilter _selectedFilter = PatientFilter.all;
  String _query = '';
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.requestedFilter;
    _loadPatients();
  }

  @override
  void didUpdateWidget(covariant PatientListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filterRequestId != oldWidget.filterRequestId) {
      setState(() => _selectedFilter = widget.requestedFilter);
      _loadPatients(showLoader: false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patients = _visiblePatients();

    return SafeArea(
      child: Column(
        children: [
          PatientListHeader(
            searchController: _searchController,
            onSearchChanged: (value) {
              setState(() => _query = value);
              _loadPatients(showLoader: false);
            },
            onAddPressed: _openCreatePatient,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadPatients(showLoader: false),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    sliver: SliverList.list(
                      children: [
                        PatientStatsStrip(patients: _patients),
                        const SizedBox(height: 12),
                        PatientFilterBar(
                          selectedFilter: _selectedFilter,
                          onChanged: (filter) {
                            setState(() => _selectedFilter = filter);
                          },
                        ),
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),
                  if (_loading)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_loadError != null)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _PatientsErrorState(
                        message: _loadError!,
                        onRetry: _loadPatients,
                      ),
                    )
                  else if (patients.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyPatientsState(
                        hasLoadedPatients: _patients.isNotEmpty,
                      ),
                    )
                  else
                    _PatientList(
                      patients: patients,
                      onPatientTap: _openPatientDetail,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<PatientSummary> _visiblePatients() {
    return _patients
        .where(_selectedFilter.accepts)
        .where((patient) => patient.matchesQuery(_query))
        .toList(growable: false);
  }

  Future<void> _loadPatients({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }

    try {
      final patients = await widget.patientGateway.listPatients(
        session: widget.session,
        search: _query,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _patients = patients;
        _loading = false;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _loadError = 'Impossible de charger les patients depuis le serveur.';
      });
    }
  }

  Future<void> _openCreatePatient() async {
    final patient = await Navigator.of(context).push<PatientSummary?>(
      MaterialPageRoute<PatientSummary?>(
        builder: (_) => PatientFormScreen(
          session: widget.session,
          patientGateway: widget.patientGateway,
        ),
      ),
    );
    if (patient != null) {
      await _loadPatients();
      widget.onQueueChanged?.call();
      if (mounted) {
        _openPatientDetail(patient);
      }
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
      await _loadPatients();
      widget.onQueueChanged?.call();
    }
  }
}

class _PatientList extends StatelessWidget {
  const _PatientList({required this.patients, required this.onPatientTap});

  final List<PatientSummary> patients;
  final ValueChanged<PatientSummary> onPatientTap;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        AdaptiveLayout.bottomContentPadding(context),
      ),
      sliver: SliverList.separated(
        itemCount: patients.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final patient = patients[index];
          return PatientCard(
            patient: patient,
            onTap: () => onPatientTap(patient),
          );
        },
      ),
    );
  }
}

class _EmptyPatientsState extends StatelessWidget {
  const _EmptyPatientsState({required this.hasLoadedPatients});

  final bool hasLoadedPatients;

  @override
  Widget build(BuildContext context) {
    final title = hasLoadedPatients
        ? 'Aucun patient trouvé'
        : 'Aucun patient enregistré';
    final message = hasLoadedPatients
        ? 'Modifiez la recherche ou le filtre actif.'
        : 'Créez un patient pour alimenter la liste depuis la base.';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.medicalGreen.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.search_off_rounded,
              color: AppColors.medicalGreen,
              size: 34,
            ),
          ),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _PatientsErrorState extends StatelessWidget {
  const _PatientsErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.cloud_off_rounded,
              color: AppColors.error,
              size: 34,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Chargement impossible',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}
