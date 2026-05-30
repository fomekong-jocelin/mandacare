import 'package:flutter/material.dart';

import '../../../app/api/api_exception.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/presentation/widgets/compact_form_field.dart';
import '../../../shared/presentation/widgets/form_section.dart';
import '../../../shared/presentation/widgets/page_header.dart';
import '../../auth/domain/auth_session.dart';
import '../../patients/data/patient_gateway.dart';
import '../../patients/domain/patient_summary.dart';
import '../../cashdesk/domain/invoice.dart';

class LabResultsFormScreen extends StatefulWidget {
  const LabResultsFormScreen({
    required this.session,
    required this.patientGateway,
    required this.patient,
    required this.visitId,
    super.key,
  });

  final AuthSession session;
  final PatientGateway patientGateway;
  final PatientSummary patient;
  final String visitId;

  @override
  State<LabResultsFormScreen> createState() => _LabResultsFormScreenState();
}

class _LabResultsFormScreenState extends State<LabResultsFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _resultsController = TextEditingController();
  final _notesController = TextEditingController();
  bool _saving = false;
  bool _normalResults = false;
  DateTime _sampleDate = DateTime.now();
  String _examType = _examTypes.first;

  static const _examTypes = [
    'Numération Formule Sanguine (NFS)',
    'Biochimie',
    'Parasitologie',
    'Sérologie',
    "Analyse d'urine",
    'Hémoculture',
    'Autre',
  ];

  List<Invoice> _invoices = [];

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    try {
      final list = await widget.patientGateway.getInvoices(
        session: widget.session,
        visitId: widget.visitId,
      );
      if (mounted) {
        setState(() {
          _invoices = list;
        });
      }
    } catch (_) {
      // Fail silently — the form is still usable without the prescribed exams card
    }
  }

  List<String> get _prescribedExams {
    final List<String> exams = [];
    for (final inv in _invoices) {
      for (final line in inv.items) {
        if (line.type == 'EXAM') {
          exams.add(line.label);
        }
      }
    }
    return exams;
  }

  @override
  void dispose() {
    _resultsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(
              title: 'Résultat de laboratoire',
              subtitle: widget.patient.fullName,
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                  children: [
                    _PatientInfoBanner(
                      patient: widget.patient,
                      dossierNumber: _dossierNumber,
                    ),
                    if (_prescribedExams.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildPrescribedExamsCard(),
                    ],
                    const SizedBox(height: 20),
                    FormSection(title: 'Prélèvement', children: _sampleFields),
                    const SizedBox(height: 20),
                    FormSection(title: 'Résultats', children: _resultFields),
                    const SizedBox(height: 20),
                    FormSection(
                      title: 'Observations',
                      children: _observationFields,
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
                  key: const ValueKey('submit-lab-results-button'),
                  onPressed: _saving ? null : _submit,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(
                    _saving
                        ? 'Validation en cours...'
                        : 'Valider et renvoyer en consultation',
                  ),
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

  List<Widget> get _sampleFields {
    return [
      CompactDropdownField(
        label: "Type d'examen",
        value: _examType,
        items: _examTypes,
        onChanged: (value) {
          if (value != null) {
            setState(() => _examType = value);
          }
        },
        icon: Icons.science_rounded,
      ),
      const SizedBox(height: 12),
      _DatePickerField(
        label: 'Prélevé le',
        value: _sampleDate,
        onChanged: (value) => setState(() => _sampleDate = value),
      ),
    ];
  }

  List<Widget> get _resultFields {
    return [
      CompactTextFormField(
        fieldKey: const ValueKey('lab-results-field'),
        controller: _resultsController,
        label: 'Résultats',
        hintText: 'Saisir les résultats du laboratoire...',
        icon: Icons.biotech_rounded,
        minLines: 4,
        maxLines: 10,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.newline,
        keyboardType: TextInputType.multiline,
        validator: (value) {
          if (!_normalResults && (value == null || value.trim().isEmpty)) {
            return 'Les résultats sont requis';
          }
          return null;
        },
      ),
      const SizedBox(height: 12),
      _NormalResultsToggle(
        value: _normalResults,
        onChanged: (value) => setState(() => _normalResults = value),
      ),
    ];
  }

  List<Widget> get _observationFields {
    return [
      CompactTextFormField(
        controller: _notesController,
        label: 'Notes / Observations',
        hintText: 'Observations complémentaires (optionnel)...',
        icon: Icons.notes_rounded,
        minLines: 3,
        maxLines: 6,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.newline,
        keyboardType: TextInputType.multiline,
      ),
    ];
  }

  String get _dossierNumber {
    final now = DateTime.now();
    final patientNum = widget.patient.patientNumber ?? '000';
    final date = '${now.year}${_twoDigits(now.month)}${_twoDigits(now.day)}';
    return 'LAB-$patientNum-$date';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_normalResults && _resultsController.text.trim().isEmpty) {
      _showError(
        'Veuillez saisir les résultats ou cocher « Résultats normaux ».',
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.patientGateway.submitLabResults(
        session: widget.session,
        visitId: widget.visitId,
        payload: CreateLabResultPayload(
          examType: _examType,
          results: _normalResults ? _normalResultText : _resultsController.text,
          observations: _notesController.text,
          sampleDate: _sampleDate,
          dossierNumber: _dossierNumber,
          isNormal: _normalResults,
        ),
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Résultats validés - retour en consultation'),
        ),
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

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');

  static const String _normalResultText = 'Résultats normaux';

  Widget _buildPrescribedExamsCard() {
    final exams = _prescribedExams;
    return FormSection(
      title: 'Examens prescrits et réglés en caisse',
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.deepHealthBlue.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.deepHealthBlue.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.assignment_turned_in_rounded,
                    color: AppColors.deepHealthBlue,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Fiche d\'examen (Caisse)',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepHealthBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...exams.map((exam) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: AppColors.medicalGreen,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          exam,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Patient info banner — shown at the top of the form
// ---------------------------------------------------------------------------

class _PatientInfoBanner extends StatelessWidget {
  const _PatientInfoBanner({
    required this.patient,
    required this.dossierNumber,
  });

  final PatientSummary patient;
  final String dossierNumber;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr =
        '${_twoDigits(now.day)}/${_twoDigits(now.month)}/${now.year}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.deepHealthBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.deepHealthBlue.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.assignment_rounded,
                size: 20,
                color: AppColors.deepHealthBlue,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Fiche de résultat',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.deepHealthBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _InfoRow(label: 'Patient', value: patient.fullName),
          _InfoRow(label: 'ID Patient', value: patient.patientNumber ?? '—'),
          _InfoRow(label: 'N° Dossier', value: dossierNumber),
          _InfoRow(label: 'Date', value: dateStr),
          _InfoRow(label: 'Profil', value: patient.sexAge),
        ],
      ),
    );
  }

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Normal-results toggle
// ---------------------------------------------------------------------------

class _NormalResultsToggle extends StatelessWidget {
  const _NormalResultsToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: value
            ? AppColors.success.withValues(alpha: 0.10)
            : AppColors.lightBackground.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: value
              ? AppColors.success.withValues(alpha: 0.40)
              : AppColors.border.withValues(alpha: 0.60),
        ),
      ),
      child: Row(
        children: [
          Icon(
            value
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 20,
            color: value ? AppColors.success : AppColors.textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Résultats normaux',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: value ? AppColors.success : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.success,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Date picker field
// ---------------------------------------------------------------------------

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${_twoDigits(value.day)}/${_twoDigits(value.month)}/${value.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CompactFieldLabel(label: label),
        const SizedBox(height: 5),
        GestureDetector(
          onTap: () => _pickDate(context),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.lightBackground.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.60),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 19,
                  color: AppColors.textSecondary.withValues(alpha: 0.70),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    dateStr,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      height: 1.18,
                    ),
                  ),
                ),
                Icon(
                  Icons.edit_calendar_rounded,
                  size: 18,
                  color: AppColors.textSecondary.withValues(alpha: 0.70),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: value,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      helpText: 'Date de prélèvement',
      cancelText: 'Annuler',
      confirmText: 'Valider',
    );
    if (picked != null) {
      onChanged(picked);
    }
  }

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');
}
