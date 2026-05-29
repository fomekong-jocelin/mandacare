import 'package:flutter/material.dart';

import '../../../app/api/api_exception.dart';
import '../../../shared/presentation/widgets/compact_form_field.dart';
import '../../../shared/presentation/widgets/form_section.dart';
import '../../../shared/presentation/widgets/page_header.dart';
import '../../auth/domain/auth_session.dart';
import '../data/patient_gateway.dart';

class PatientFormScreen extends StatefulWidget {
  const PatientFormScreen({
    required this.session,
    required this.patientGateway,
    super.key,
  });

  final AuthSession session;
  final PatientGateway patientGateway;

  @override
  State<PatientFormScreen> createState() => _PatientFormScreenState();
}

class _PatientFormScreenState extends State<PatientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _addressController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _reasonController = TextEditingController();
  String _sex = 'F';
  String _priority = 'Standard';
  bool _saving = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    _emergencyContactController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const PageHeader(
              title: 'Nouveau patient',
              subtitle: 'Créer un dossier médical',
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                  children: [
                    FormSection(
                      title: 'Identité',
                      children: [
                        _AppTextField(
                          controller: _fullNameController,
                          label: 'Nom complet',
                          icon: Icons.person_rounded,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          validator: _fullNameRequired,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _AppTextField(
                                controller: _ageController,
                                label: 'Âge',
                                icon: Icons.cake_rounded,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                                validator: _ageRequired,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _DropdownField(
                                label: 'Sexe',
                                value: _sex,
                                items: const ['F', 'M'],
                                icon: Icons.wc_rounded,
                                onChanged: (value) {
                                  setState(() => _sex = value ?? 'F');
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _AppTextField(
                          controller: _phoneController,
                          label: 'Téléphone',
                          icon: Icons.phone_rounded,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          validator: _required,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    FormSection(
                      title: 'Contact et prise en charge',
                      children: [
                        _AppTextField(
                          controller: _addressController,
                          label: 'Adresse',
                          icon: Icons.location_on_rounded,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 12),
                        _AppTextField(
                          controller: _emergencyContactController,
                          label: 'Contact urgence',
                          icon: Icons.emergency_rounded,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        _DropdownField(
                          label: 'Priorité',
                          value: _priority,
                          items: const ['Standard', 'Surveillance', 'Urgent'],
                          icon: Icons.stars_rounded,
                          onChanged: (value) {
                            setState(() => _priority = value ?? 'Standard');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    FormSection(
                      title: "Motif d'arrivée",
                      children: [
                        _AppTextField(
                          controller: _reasonController,
                          label: 'Motif',
                          icon: Icons.medical_information_rounded,
                          maxLines: 3,
                          textCapitalization: TextCapitalization.sentences,
                          validator: _required,
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
                  key: const ValueKey('save-patient-button'),
                  onPressed: _saving ? null : _submit,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(
                    _saving ? 'Enregistrement...' : 'Enregistrer patient',
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

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Champ requis';
    }
    return null;
  }

  String? _fullNameRequired(String? value) {
    final requiredError = _required(value);
    if (requiredError != null) {
      return requiredError;
    }
    if (value!.trim().split(RegExp(r'\s+')).length < 2) {
      return 'Prénom et nom requis';
    }
    return null;
  }

  String? _ageRequired(String? value) {
    final requiredError = _required(value);
    if (requiredError != null) {
      return requiredError;
    }
    final age = int.tryParse(value!.trim());
    if (age == null || age < 0 || age > 130) {
      return 'Âge invalide';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    try {
      final patient = await widget.patientGateway.createPatient(
        session: widget.session,
        payload: _payload(),
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient enregistré en base')),
      );
      Navigator.of(context).pop(patient);
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

  CreatePatientPayload _payload() {
    final name = _splitName(_fullNameController.text);
    return CreatePatientPayload(
      firstName: name.firstName,
      lastName: name.lastName,
      sex: _sex == 'F' ? 'FEMALE' : 'MALE',
      declaredAge: int.parse(_ageController.text.trim()),
      phone: _phoneController.text.trim(),
      city: _blankToNull(_addressController.text),
      emergencyContactPhone: _blankToNull(_emergencyContactController.text),
      arrivalReason: _reasonController.text.trim(),
      priority: switch (_priority) {
        'Urgent' => 'URGENT',
        'Surveillance' => 'SURVEILLANCE',
        _ => 'STANDARD',
      },
    );
  }

  ({String firstName, String lastName}) _splitName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    return (firstName: parts.first, lastName: parts.skip(1).join(' '));
  }

  String? _blankToNull(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
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

class _AppTextField extends StatelessWidget {
  const _AppTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final int maxLines;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return CompactTextFormField(
      controller: controller,
      label: label,
      icon: icon,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      maxLines: maxLines,
      validator: validator,
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
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
