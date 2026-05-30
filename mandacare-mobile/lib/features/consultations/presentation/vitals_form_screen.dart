import 'package:flutter/material.dart';

import '../../../app/api/api_exception.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/presentation/widgets/compact_form_field.dart';
import '../../../shared/presentation/widgets/form_section.dart';
import '../../../shared/presentation/widgets/page_header.dart';
import '../../auth/domain/auth_session.dart';
import '../../patients/data/patient_gateway.dart';
import '../../patients/domain/patient_summary.dart';
import '../../patients/domain/vitals_summary.dart';

class VitalsFormScreen extends StatefulWidget {
  const VitalsFormScreen({
    required this.session,
    required this.patientGateway,
    required this.patient,
    required this.visitId,
    this.existingVitals,
    super.key,
  });

  final AuthSession session;
  final PatientGateway patientGateway;
  final PatientSummary patient;
  final String visitId;
  final VitalsSummary? existingVitals;

  @override
  State<VitalsFormScreen> createState() => _VitalsFormScreenState();
}

class _VitalsFormScreenState extends State<VitalsFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _temperatureController = TextEditingController();
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _pulseController = TextEditingController();
  final _respiratoryController = TextEditingController();
  final _oxygenController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _glucoseController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _weightController.addListener(_refreshBmi);
    _heightController.addListener(_refreshBmi);

    if (widget.existingVitals != null) {
      final v = widget.existingVitals!;
      _temperatureController.text = v.temperature?.toString() ?? '';
      _systolicController.text = v.systolicPressure?.toString() ?? '';
      _diastolicController.text = v.diastolicPressure?.toString() ?? '';
      _pulseController.text = v.pulse?.toString() ?? '';
      _respiratoryController.text = v.respiratoryRate?.toString() ?? '';
      _oxygenController.text = v.oxygenSaturation?.toString() ?? '';
      _weightController.text = v.weight?.toString() ?? '';
      _heightController.text = v.height?.toString() ?? '';
      _glucoseController.text = v.bloodGlucose?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _temperatureController.dispose();
    _systolicController.dispose();
    _diastolicController.dispose();
    _pulseController.dispose();
    _respiratoryController.dispose();
    _oxygenController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _glucoseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(title: 'Constantes', subtitle: widget.patient.fullName),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                  children: [
                    FormSection(title: 'Signes vitaux', children: _vitalFields),
                    const SizedBox(height: 20),
                    FormSection(title: 'Mesures', children: _measureFields),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton.icon(
                  key: const ValueKey('save-vitals-button'),
                  onPressed: _saving ? null : _submit,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(_saving ? 'Enregistrement...' : 'Enregistrer'),
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

  List<Widget> get _vitalFields {
    return [
      _VitalsField(
        key: const ValueKey('vitals-temperature-field'),
        controller: _temperatureController,
        label: 'Température (°C)',
        helperText: '30 à 45 °C',
        icon: Icons.thermostat_rounded,
        validator: _decimalRange(30, 45),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _VitalsField(
              key: const ValueKey('vitals-systolic-field'),
              controller: _systolicController,
              label: 'Systolique',
              helperText: '50 à 260 mmHg',
              icon: Icons.monitor_heart_rounded,
              validator: _intRange(50, 260),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _VitalsField(
              key: const ValueKey('vitals-diastolic-field'),
              controller: _diastolicController,
              label: 'Diastolique',
              helperText: '30 à 160 mmHg',
              icon: Icons.monitor_heart_rounded,
              validator: _intRange(30, 160),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _VitalsField(
              key: const ValueKey('vitals-pulse-field'),
              controller: _pulseController,
              label: 'Pouls',
              helperText: '20 à 240/min',
              icon: Icons.favorite_rounded,
              validator: _intRange(20, 240),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _VitalsField(
              key: const ValueKey('vitals-oxygen-field'),
              controller: _oxygenController,
              label: 'SpO2 (%)',
              helperText: '50 à 100 %',
              icon: Icons.air_rounded,
              validator: _intRange(50, 100),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      _VitalsField(
        key: const ValueKey('vitals-respiratory-field'),
        controller: _respiratoryController,
        label: 'Fréquence respiratoire',
        helperText: '5 à 80/min',
        icon: Icons.waves_rounded,
        validator: _intRange(5, 80),
      ),
    ];
  }

  List<Widget> get _measureFields {
    return [
      Row(
        children: [
          Expanded(
            child: _VitalsField(
              key: const ValueKey('vitals-weight-field'),
              controller: _weightController,
              label: 'Poids (kg)',
              helperText: '1 à 300 kg',
              icon: Icons.scale_rounded,
              validator: _decimalRange(1, 300),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _VitalsField(
              key: const ValueKey('vitals-height-field'),
              controller: _heightController,
              label: 'Taille (cm)',
              helperText: '30 à 250 cm',
              icon: Icons.height_rounded,
              validator: _decimalRange(30, 250),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      _BmiPreview(value: _bmi),
      const SizedBox(height: 12),
      _VitalsField(
        key: const ValueKey('vitals-glucose-field'),
        controller: _glucoseController,
        label: 'Glycémie',
        helperText: '0.10 à 999.99',
        icon: Icons.bloodtype_rounded,
        validator: _decimalRange(0.1, 999.99),
      ),
    ];
  }

  double? get _bmi {
    final weight = _decimalValue(_weightController.text);
    final height = _decimalValue(_heightController.text);
    if (weight == null ||
        height == null ||
        weight < 1 ||
        weight > 300 ||
        height < 30 ||
        height > 250) {
      return null;
    }
    final meters = height / 100;
    return weight / (meters * meters);
  }

  String? Function(String?) _intRange(int min, int max) {
    return (value) {
      if (value == null || value.trim().isEmpty) {
        return null;
      }
      final parsed = int.tryParse(value.trim());
      return parsed == null || parsed < min || parsed > max
          ? 'Valeur invalide'
          : null;
    };
  }

  String? Function(String?) _decimalRange(double min, double max) {
    return (value) {
      if (value == null || value.trim().isEmpty) {
        return null;
      }
      final parsed = _decimalValue(value);
      return parsed == null || parsed < min || parsed > max
          ? 'Valeur invalide'
          : null;
    };
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final payload = _payload();
    if (!payload.hasMeasurement) {
      _showError('Saisissez au moins une constante.');
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.patientGateway.createVitals(
        session: widget.session,
        visitId: widget.visitId,
        payload: payload,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Constantes enregistrées')));
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

  CreateVitalsPayload _payload() {
    return CreateVitalsPayload(
      temperature: _decimalValue(_temperatureController.text),
      systolicPressure: _intValue(_systolicController.text),
      diastolicPressure: _intValue(_diastolicController.text),
      pulse: _intValue(_pulseController.text),
      respiratoryRate: _intValue(_respiratoryController.text),
      oxygenSaturation: _intValue(_oxygenController.text),
      weight: _decimalValue(_weightController.text),
      height: _decimalValue(_heightController.text),
      bloodGlucose: _decimalValue(_glucoseController.text),
    );
  }

  int? _intValue(String value) => int.tryParse(value.trim());

  double? _decimalValue(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

  void _refreshBmi() => setState(() {});

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _VitalsField extends StatelessWidget {
  const _VitalsField({
    required super.key,
    required this.controller,
    required this.label,
    required this.helperText,
    required this.icon,
    required this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String helperText;
  final IconData icon;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    return CompactTextFormField(
      controller: controller,
      label: label,
      helperText: helperText,
      icon: icon,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      validator: validator,
    );
  }
}

class _BmiPreview extends StatelessWidget {
  const _BmiPreview({required this.value});

  final double? value;

  @override
  Widget build(BuildContext context) {
    final bmi = value == null
        ? 'poids et taille valides requis'
        : value!.toStringAsFixed(2);
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.medicalGreen.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.centerLeft,
      child: Text(
        'IMC: $bmi',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.medicalGreen,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
