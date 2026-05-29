import 'package:flutter/material.dart';

import '../../../app/api/api_exception.dart';
import '../../../shared/presentation/widgets/compact_form_field.dart';
import '../../../shared/presentation/widgets/form_section.dart';
import '../../../shared/presentation/widgets/page_header.dart';
import '../../auth/domain/auth_session.dart';
import '../data/patient_gateway.dart';
import '../domain/patient_summary.dart';

class PatientVisitFormScreen extends StatefulWidget {
  const PatientVisitFormScreen({
    required this.session,
    required this.patientGateway,
    required this.patient,
    super.key,
  });

  final AuthSession session;
  final PatientGateway patientGateway;
  final PatientSummary patient;

  @override
  State<PatientVisitFormScreen> createState() => _PatientVisitFormScreenState();
}

class _PatientVisitFormScreenState extends State<PatientVisitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  String _priority = _VisitPriorityOption.standard.label;
  String _targetService = _TargetServiceOption.consultation.label;
  bool _saving = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(
              title: 'Nouvelle visite',
              subtitle: widget.patient.fullName,
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                  children: [
                    FormSection(
                      title: "Motif d'arrivée",
                      children: [
                        _VisitTextField(
                          controller: _reasonController,
                          label: 'Motif',
                          icon: Icons.medical_information_rounded,
                          maxLines: 4,
                          textCapitalization: TextCapitalization.sentences,
                          validator: _required,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    FormSection(
                      title: 'Orientation',
                      children: [
                        _VisitDropdown(
                          label: 'Priorité',
                          value: _priority,
                          items: _VisitPriorityOption.labels,
                          icon: Icons.stars_rounded,
                          onChanged: (value) {
                            setState(() => _priority = value ?? _priority);
                          },
                        ),
                        const SizedBox(height: 12),
                        _VisitDropdown(
                          label: 'Service cible',
                          value: _targetService,
                          items: _TargetServiceOption.labels,
                          icon: Icons.local_hospital_rounded,
                          onChanged: (value) {
                            setState(
                              () => _targetService = value ?? _targetService,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton.icon(
                  key: const ValueKey('save-visit-button'),
                  onPressed: _saving ? null : _submit,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(_saving ? 'Ouverture...' : 'Ouvrir la visite'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Champ requis';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final patientId = widget.patient.id;
    if (patientId == null) {
      _showError('Patient non synchronisé avec le serveur.');
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.patientGateway.createVisit(
        session: widget.session,
        patientId: patientId,
        payload: _payload(),
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Visite ouverte dans la file du jour')),
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (exception) {
      _showError(exception.message);
    } catch (_) {
      _showError('Connexion impossible au backend.');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  CreateVisitPayload _payload() {
    return CreateVisitPayload(
      reason: _reasonController.text.trim(),
      priority: _VisitPriorityOption.fromLabel(_priority).apiValue,
      targetService: _TargetServiceOption.fromLabel(_targetService).apiValue,
    );
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _VisitTextField extends StatelessWidget {
  const _VisitTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return CompactTextFormField(
      controller: controller,
      label: label,
      icon: icon,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      validator: validator,
    );
  }
}

class _VisitDropdown extends StatelessWidget {
  const _VisitDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.icon,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return CompactDropdownField(
      label: label,
      value: value,
      items: items,
      onChanged: onChanged,
      icon: icon,
    );
  }
}

enum _VisitPriorityOption {
  standard('Standard', 'STANDARD'),
  surveillance('Surveillance', 'SURVEILLANCE'),
  urgent('Urgent', 'URGENT');

  const _VisitPriorityOption(this.label, this.apiValue);

  final String label;
  final String apiValue;

  static List<String> get labels {
    return values.map((option) => option.label).toList(growable: false);
  }

  static _VisitPriorityOption fromLabel(String label) {
    return values.firstWhere(
      (option) => option.label == label,
      orElse: () => _VisitPriorityOption.standard,
    );
  }
}

enum _TargetServiceOption {
  vitals('Constantes', 'VITALS'),
  consultation('Consultation', 'CONSULTATION'),
  lab('Laboratoire', 'LAB'),
  cashDesk('Caisse', 'CASH_DESK');

  const _TargetServiceOption(this.label, this.apiValue);

  final String label;
  final String apiValue;

  static List<String> get labels {
    return values.map((option) => option.label).toList(growable: false);
  }

  static _TargetServiceOption fromLabel(String label) {
    return values.firstWhere(
      (option) => option.label == label,
      orElse: () => _TargetServiceOption.consultation,
    );
  }
}
