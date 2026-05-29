import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/api/api_exception.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/presentation/widgets/form_section.dart';
import '../../../shared/presentation/widgets/page_header.dart';
import '../../auth/domain/auth_session.dart';
import '../../patients/data/patient_gateway.dart';
import '../../patients/domain/patient_summary.dart';
import '../../patients/domain/vitals_summary.dart';
import '../domain/consultation_decision.dart';
import '../domain/create_consultation_payload.dart';
import '../domain/prescription.dart';
import '../../../shared/presentation/widgets/compact_form_field.dart';
import 'widgets/consultation_decision_selector.dart';
import 'widgets/consultation_text_field.dart';
import 'widgets/consultation_vitals_summary.dart';

class ConsultationFormScreen extends StatefulWidget {
  const ConsultationFormScreen({
    required this.session,
    required this.patientGateway,
    required this.patient,
    required this.visitId,
    required this.vitals,
    super.key,
  });

  final AuthSession session;
  final PatientGateway patientGateway;
  final PatientSummary patient;
  final String visitId;
  final VitalsSummary? vitals;

  @override
  State<ConsultationFormScreen> createState() => _ConsultationFormScreenState();
}

class _ConsultationFormScreenState extends State<ConsultationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _symptomsController = TextEditingController();
  final _clinicalExamController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _adviceController = TextEditingController();

  ConsultationDecision _decision = ConsultationDecision.keepInConsultation;
  bool _saving = false;
  bool _loadingDraft = false;
  String? _originalStatus;
  final List<PrescriptionItem> _prescriptionItems = [];
  final List<_PrescriptionItemControllers> _prescriptionControllers = [];

  @override
  void initState() {
    super.initState();
    _decision = switch (widget.patient.status) {
      PatientStatus.lab => ConsultationDecision.sendToLab,
      PatientStatus.released => ConsultationDecision.releasePatient,
      _ => ConsultationDecision.keepInConsultation,
    };
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    final patientId = widget.patient.id;
    if (patientId == null) {
      return;
    }

    setState(() => _loadingDraft = true);
    try {
      final items = await widget.patientGateway.getPatientTimeline(
        session: widget.session,
        patientId: patientId,
      );
      final matchIndex = items.indexWhere(
        (item) => item.visitId == widget.visitId,
      );
      if (matchIndex != -1) {
        final saved = items[matchIndex].consultation;
        if (saved != null && mounted) {
          setState(() {
            _symptomsController.text = saved.symptoms;
            _clinicalExamController.text = saved.clinicalExam;
            _diagnosisController.text = saved.diagnosis;
            _adviceController.text = saved.advice ?? '';
            _originalStatus = saved.status;
          });

          try {
            final prescription = await widget.patientGateway.getPrescription(
              session: widget.session,
              consultationId: saved.id,
            );
            if (prescription != null && mounted) {
              setState(() {
                _prescriptionItems.clear();
                for (final ctrl in _prescriptionControllers) {
                  ctrl.dispose();
                }
                _prescriptionControllers.clear();

                _prescriptionItems.addAll(prescription.items);
                for (final item in prescription.items) {
                  _prescriptionControllers.add(
                    _PrescriptionItemControllers(item),
                  );
                }
              });
            }
          } catch (_) {}
        }
      }
    } catch (_) {
      // Gracefully ignore loading errors for drafts
    } finally {
      if (mounted) {
        setState(() => _loadingDraft = false);
      }
    }
  }

  @override
  void dispose() {
    _symptomsController.dispose();
    _clinicalExamController.dispose();
    _diagnosisController.dispose();
    _adviceController.dispose();
    for (final ctrl in _prescriptionControllers) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _addPrescriptionItem() {
    setState(() {
      final item = PrescriptionItem(id: UniqueKey().toString(), drugName: '');
      _prescriptionItems.add(item);
      _prescriptionControllers.add(_PrescriptionItemControllers(item));
    });
  }

  void _removePrescriptionItem(int index) {
    setState(() {
      _prescriptionItems.removeAt(index);
      _prescriptionControllers.removeAt(index).dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(
              title: 'Consultation',
              subtitle: widget.patient.fullName,
            ),
            if (_loadingDraft)
              const LinearProgressIndicator(
                color: AppColors.medicalGreen,
                backgroundColor: Colors.transparent,
                minHeight: 2,
              ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  key: const ValueKey('consultation-form-scroll'),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 104),
                  children: [
                    _PatientContextCard(patient: widget.patient),
                    const SizedBox(height: 12),
                    ConsultationVitalsSummary(vitals: widget.vitals),
                    const SizedBox(height: 20),
                    FormSection(
                      title: 'Observation clinique',
                      children: [
                        ConsultationTextField(
                          key: const ValueKey('consultation-symptoms-field'),
                          controller: _symptomsController,
                          label: 'Symptômes et plainte',
                          hintText: 'Ex. douleur, fièvre, évolution, contexte',
                          icon: Icons.sick_rounded,
                          minLines: 2,
                          maxLines: 3,
                          validator: _required,
                        ),
                        const SizedBox(height: 12),
                        ConsultationTextField(
                          key: const ValueKey(
                            'consultation-clinical-exam-field',
                          ),
                          controller: _clinicalExamController,
                          label: 'Examen clinique',
                          hintText: 'Ex. état général, auscultation, abdomen',
                          icon: Icons.medical_information_rounded,
                          minLines: 2,
                          maxLines: 3,
                          validator: _required,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    FormSection(
                      title: 'Conclusion',
                      children: [
                        ConsultationTextField(
                          key: const ValueKey('consultation-diagnosis-field'),
                          controller: _diagnosisController,
                          label: 'Diagnostic',
                          hintText: 'Diagnostic retenu ou hypothèse principale',
                          icon: Icons.fact_check_rounded,
                          minLines: 1,
                          maxLines: 2,
                          validator: _required,
                        ),
                        const SizedBox(height: 12),
                        ConsultationTextField(
                          key: const ValueKey('consultation-advice-field'),
                          controller: _adviceController,
                          label: 'Conduite à tenir',
                          hintText: 'Traitement, surveillance, rendez-vous',
                          icon: Icons.assignment_turned_in_rounded,
                          minLines: 2,
                          maxLines: 3,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    FormSection(
                      title: 'Ordonnance (Rx)',
                      children: [
                        if (_prescriptionItems.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 24,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.lightBackground.withValues(
                                alpha: 0.2,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.border.withValues(alpha: 0.4),
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.receipt_long_rounded,
                                  color: AppColors.medicalGreen,
                                  size: 36,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Aucun médicament prescrit.',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _prescriptionItems.length,
                            itemBuilder: (context, index) {
                              final ctrl = _prescriptionControllers[index];
                              return Card(
                                elevation: 0,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                    color: AppColors.border.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Médicament #${index + 1}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall
                                                ?.copyWith(
                                                  color:
                                                      AppColors.deepHealthBlue,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline_rounded,
                                              color: Colors.redAccent,
                                              size: 20,
                                            ),
                                            onPressed: () =>
                                                _removePrescriptionItem(index),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      CompactTextFormField(
                                        controller: ctrl.drugName,
                                        label: 'Nom du médicament',
                                        hintText: 'Ex: Paracétamol',
                                        icon: Icons.medication_rounded,
                                        validator: _required,
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: CompactTextFormField(
                                              controller: ctrl.form,
                                              label: 'Forme',
                                              hintText: 'Ex: Comprimé',
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: CompactTextFormField(
                                              controller: ctrl.dosage,
                                              label: 'Dosage',
                                              hintText: 'Ex: 500mg',
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: CompactTextFormField(
                                              controller: ctrl.frequency,
                                              label: 'Fréquence',
                                              hintText: 'Ex: 3x/jour',
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: CompactTextFormField(
                                              controller: ctrl.duration,
                                              label: 'Durée',
                                              hintText: 'Ex: 5 jours',
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            flex: 1,
                                            child: CompactTextFormField(
                                              controller: ctrl.quantity,
                                              label: 'Boîtes',
                                              hintText: 'Ex: 2',
                                              keyboardType:
                                                  TextInputType.number,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            flex: 2,
                                            child: CompactTextFormField(
                                              controller: ctrl.instructions,
                                              label: 'Instructions',
                                              hintText: 'Ex: Après repas',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _addPrescriptionItem,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Ajouter un médicament'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(40),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    FormSection(
                      title: 'Décision',
                      children: [
                        ConsultationDecisionSelector(
                          value: _decision,
                          onChanged: (decision) {
                            setState(() => _decision = decision);
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
                child: Row(
                  children: [
                    if (_originalStatus != 'VALIDATED' &&
                        _originalStatus != 'CORRECTED') ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const ValueKey('save-draft-button'),
                          onPressed: _saving
                              ? null
                              : () => _submit(isDraft: true),
                          icon: const Icon(Icons.save_as_rounded),
                          label: const Text('Brouillon'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: FilledButton.icon(
                        key: const ValueKey('save-consultation-button'),
                        onPressed: _saving
                            ? null
                            : () => _submit(isDraft: false),
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(_submitIcon),
                        label: Text(_saving ? 'Validation...' : _submitLabel),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                    ),
                  ],
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

  Future<void> _submit({required bool isDraft}) async {
    if (!isDraft) {
      if (!_formKey.currentState!.validate()) {
        return;
      }
    }

    String? correctionMotif;
    if (!isDraft &&
        (_originalStatus == 'VALIDATED' || _originalStatus == 'CORRECTED')) {
      correctionMotif = await _showCorrectionMotifDialog();
      if (correctionMotif == null) {
        return; // user cancelled
      }
    }

    setState(() => _saving = true);
    try {
      final consultationId = await widget.patientGateway.createConsultation(
        session: widget.session,
        visitId: widget.visitId,
        payload: _payload(isDraft: isDraft, correctionMotif: correctionMotif),
      );

      final prescriptionItems = <CreatePrescriptionItemPayload>[];
      for (final ctrl in _prescriptionControllers) {
        final drug = ctrl.drugName.text;
        if (drug.isNotEmpty || isDraft) {
          prescriptionItems.add(
            CreatePrescriptionItemPayload(
              drugName: drug,
              form: ctrl.form.text.isNotEmpty ? ctrl.form.text : null,
              dosage: ctrl.dosage.text.isNotEmpty ? ctrl.dosage.text : null,
              frequency: ctrl.frequency.text.isNotEmpty
                  ? ctrl.frequency.text
                  : null,
              duration: ctrl.duration.text.isNotEmpty
                  ? ctrl.duration.text
                  : null,
              quantity: int.tryParse(ctrl.quantity.text),
              instructions: ctrl.instructions.text.isNotEmpty
                  ? ctrl.instructions.text
                  : null,
            ),
          );
        }
      }

      if (_prescriptionItems.isNotEmpty || isDraft) {
        await widget.patientGateway.savePrescription(
          session: widget.session,
          consultationId: consultationId,
          payload: CreatePrescriptionPayload(
            status: isDraft
                ? PrescriptionStatus.draft
                : PrescriptionStatus.validated,
            items: prescriptionItems,
          ),
        );
      }

      if (!mounted) {
        return;
      }

      if (!isDraft && _prescriptionItems.isNotEmpty) {
        final relativeUrl = '/consultations/$consultationId/prescription/pdf';
        final baseUrlString = widget.patientGateway is BackendPatientGateway
            ? (widget.patientGateway as BackendPatientGateway).apiClient.baseUrl
            : "http://localhost:8080/api/v1";
        final fullUrl = '$baseUrlString$relativeUrl';

        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Consultation validée !'),
              content: const Text(
                'L\'ordonnance a été générée avec succès. Souhaitez-vous la prévisualiser et l\'imprimer ?',
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
                      final success = await launchUrl(url, mode: LaunchMode.externalApplication);
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
                  label: const Text('Prévisualiser & Imprimer'),
                ),
              ],
            );
          },
        );
      }

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isDraft
                ? 'Brouillon de consultation enregistré'
                : 'Consultation validée et verrouillée',
          ),
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

  CreateConsultationPayload _payload({
    required bool isDraft,
    String? correctionMotif,
  }) {
    return CreateConsultationPayload(
      symptoms: _symptomsController.text,
      clinicalExam: _clinicalExamController.text,
      diagnosis: _diagnosisController.text,
      advice: _adviceController.text,
      decision: _decision,
      status: isDraft ? 'DRAFT' : 'VALIDATED',
      correctionMotif: correctionMotif,
    );
  }

  String get _submitLabel {
    return switch (_decision) {
      ConsultationDecision.keepInConsultation => 'Enregistrer',
      ConsultationDecision.sendToLab => 'Envoyer au labo',
      ConsultationDecision.releasePatient => 'Terminer la visite',
    };
  }

  IconData get _submitIcon {
    return switch (_decision) {
      ConsultationDecision.keepInConsultation => Icons.save_rounded,
      ConsultationDecision.sendToLab => Icons.science_rounded,
      ConsultationDecision.releasePatient => Icons.check_rounded,
    };
  }

  Future<String?> _showCorrectionMotifDialog() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Motif de correction requis'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Cette consultation a déjà été validée. Pour enregistrer vos modifications, veuillez indiquer un motif de correction.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                CompactTextFormField(
                  controller: controller,
                  label: 'Motif de correction',
                  hintText: 'Ex: Correction d\'une erreur de dosage',
                  icon: Icons.edit_note_rounded,
                  validator: _required,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final text = controller.text.trim();
                  Navigator.of(context).pop(text);
                }
              },
              child: const Text('Valider'),
            ),
          ],
        );
      },
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

class _PatientContextCard extends StatelessWidget {
  const _PatientContextCard({required this.patient});

  final PatientSummary patient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.deepHealthBlue,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white.withValues(alpha: 0.12),
            foregroundColor: Colors.white,
            child: Text(patient.initials),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.reason,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${patient.sexAge} · ${patient.lastVisit}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrescriptionItemControllers {
  _PrescriptionItemControllers(PrescriptionItem item)
    : drugName = TextEditingController(text: item.drugName),
      form = TextEditingController(text: item.form ?? ''),
      dosage = TextEditingController(text: item.dosage ?? ''),
      frequency = TextEditingController(text: item.frequency ?? ''),
      duration = TextEditingController(text: item.duration ?? ''),
      quantity = TextEditingController(text: item.quantity?.toString() ?? ''),
      instructions = TextEditingController(text: item.instructions ?? '');

  final TextEditingController drugName;
  final TextEditingController form;
  final TextEditingController dosage;
  final TextEditingController frequency;
  final TextEditingController duration;
  final TextEditingController quantity;
  final TextEditingController instructions;

  void dispose() {
    drugName.dispose();
    form.dispose();
    dosage.dispose();
    frequency.dispose();
    duration.dispose();
    quantity.dispose();
    instructions.dispose();
  }
}
