import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/api/api_client.dart';
import '../../../shared/presentation/document_preview_share_screen.dart';

import '../../../app/api/api_exception.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/presentation/widgets/form_section.dart';
import '../../../shared/presentation/widgets/page_header.dart';
import '../../auth/domain/auth_session.dart';
import '../../patients/data/patient_gateway.dart';
import '../../patients/domain/patient_summary.dart';
import '../../patients/domain/patient_timeline_item.dart';
import '../../patients/domain/vitals_summary.dart';
import '../domain/consultation_decision.dart';
import '../domain/create_consultation_payload.dart';
import '../domain/exam.dart';
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
  List<Exam> _exams = [];
  bool _loadingExams = false;
  final Set<String> _selectedExamIds = {};
  String _examSearchQuery = '';
  PatientLabResultSummary? _labResult;

  @override
  void initState() {
    super.initState();
    _decision = switch (widget.patient.status) {
      PatientStatus.cashDesk => ConsultationDecision.releasePatient,
      PatientStatus.lab => ConsultationDecision.sendToLab,
      PatientStatus.released => ConsultationDecision.releasePatient,
      _ => ConsultationDecision.keepInConsultation,
    };
    _initData();
  }

  Future<void> _initData() async {
    await _loadExams();
    if (mounted) {
      await _loadDraft();
    }
  }

  Future<void> _loadExams() async {
    setState(() => _loadingExams = true);
    try {
      final list = await widget.patientGateway.listActiveExams(session: widget.session);
      if (mounted) {
        setState(() {
          _exams = list;
          _loadingExams = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingExams = false);
      }
    }
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
        final timelineItem = items[matchIndex];
        if (timelineItem.labResult != null && mounted) {
          setState(() {
            _labResult = timelineItem.labResult;
          });
        }
        final saved = timelineItem.consultation;
        if (saved != null && mounted) {
          setState(() {
            _symptomsController.text = saved.symptoms;
            _clinicalExamController.text = saved.clinicalExam;
            _diagnosisController.text = saved.diagnosis;
            _adviceController.text = saved.advice ?? '';
            _decision = saved.decision;
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

          try {
            final invoices = await widget.patientGateway.getInvoices(
              session: widget.session,
              visitId: widget.visitId,
            );
            final examLabels = invoices
                .expand((inv) => inv.items)
                .where((item) => item.type == 'EXAM')
                .map((item) => item.label.trim().toLowerCase())
                .toSet();

            if (examLabels.isNotEmpty && mounted) {
              setState(() {
                for (final exam in _exams) {
                  final examName = exam.name.trim().toLowerCase();
                  final examCode = exam.code.trim().toLowerCase();
                  final combined = '${exam.code} - ${exam.name}'.trim().toLowerCase();

                  if (examLabels.contains(examName) ||
                      examLabels.contains(examCode) ||
                      examLabels.contains(combined)) {
                    _selectedExamIds.add(exam.id);
                  }
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
                    if (_labResult != null) ...[
                      _buildLabResultsSection(_labResult!),
                      const SizedBox(height: 20),
                    ],
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
                        if (_decision == ConsultationDecision.sendToLab) ...[
                          const SizedBox(height: 18),
                          Text(
                            'Examens à prescrire',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: AppColors.deepHealthBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          if (_loadingExams)
                            const Center(child: CircularProgressIndicator())
                          else if (_exams.isEmpty)
                            const Text('Aucun examen disponible dans le catalogue.')
                          else
                            _buildExamsSelector(),
                        ],
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
        final apiClient = widget.patientGateway is BackendPatientGateway
            ? (widget.patientGateway as BackendPatientGateway).apiClient
            : ApiClient(baseUrl: baseUrlString);

        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Consultation validée !'),
              content: const Text(
                'L\'ordonnance a été générée avec succès. Souhaitez-vous la prévisualiser, la télécharger ou la partager ?',
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
                          title: 'Ordonnance médicale',
                          session: widget.session,
                          apiClient: apiClient,
                          entityId: consultationId,
                          entityType: 'PRESCRIPTION',
                          phoneNumber: widget.patient.phoneNumber,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.preview_rounded),
                  label: const Text('Prévisualiser'),
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

  Widget _buildExamsSelector() {
    final filtered = _exams.where((exam) {
      if (_examSearchQuery.trim().isEmpty) return true;
      return exam.name.toLowerCase().contains(_examSearchQuery.trim().toLowerCase()) ||
          exam.code.toLowerCase().contains(_examSearchQuery.trim().toLowerCase()) ||
          exam.category.toLowerCase().contains(_examSearchQuery.trim().toLowerCase());
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          key: const ValueKey('exam-search-field'),
          decoration: InputDecoration(
            hintText: 'Rechercher un examen (ex: NFS, Glycémie)',
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
          onChanged: (val) => setState(() => _examSearchQuery = val),
        ),
        const SizedBox(height: 10),
        Container(
          constraints: const BoxConstraints(maxHeight: 200),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: filtered.length,
            itemBuilder: (context, idx) {
              final exam = filtered[idx];
              final isSelected = _selectedExamIds.contains(exam.id);
              return CheckboxListTile(
                key: ValueKey('exam-tile-${exam.code}'),
                controlAffinity: ListTileControlAffinity.leading,
                value: isSelected,
                title: Text(
                  exam.name,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: Text(
                  '${exam.category} · ${exam.price.toStringAsFixed(0)} Frs',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedExamIds.add(exam.id);
                    } else {
                      _selectedExamIds.remove(exam.id);
                    }
                  });
                },
              );
            },
          ),
        ),
        if (_selectedExamIds.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _selectedExamIds.map((id) {
              final exam = _exams.firstWhere((e) => e.id == id);
              return Chip(
                label: Text(
                  exam.code,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                onDeleted: () {
                  setState(() => _selectedExamIds.remove(id));
                },
                backgroundColor: AppColors.medicalGreen.withValues(alpha: 0.1),
                deleteIconColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: const BorderSide(color: AppColors.medicalGreen, width: 0.5),
                ),
              );
            }).toList(),
          ),
        ]
      ],
    );
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
      prescribedExams: _decision == ConsultationDecision.sendToLab
          ? _selectedExamIds.toList(growable: false)
          : null,
    );
  }

  String get _submitLabel {
    return switch (_decision) {
      ConsultationDecision.keepInConsultation => 'Enregistrer',
      ConsultationDecision.sendToLab => 'Envoyer à la caisse',
      ConsultationDecision.releasePatient => 'Envoyer à la caisse',
    };
  }

  IconData get _submitIcon {
    return switch (_decision) {
      ConsultationDecision.keepInConsultation => Icons.save_rounded,
      ConsultationDecision.sendToLab => Icons.payments_rounded,
      ConsultationDecision.releasePatient => Icons.payments_rounded,
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

  Widget _buildLabResultsSection(PatientLabResultSummary labResult) {
    final badgeColor = labResult.isNormal
        ? AppColors.medicalGreen
        : AppColors.error;
    final badgeText = labResult.isNormal ? 'Normal' : 'À interpréter';
    final examTitle = _labExamTitle(labResult.examType);
    final examDetails = _labExamDetails(labResult.examType);
    final analysisBlocks = _labAnalysisBlocks(labResult.results);
    final observations = labResult.observations?.trim();

    return FormSection(
      title: 'Résultats laboratoire',
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.medicalGreen.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.science_rounded,
                color: AppColors.medicalGreen,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    examTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.16,
                    ),
                  ),
                  if (examDetails != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      examDetails,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.medicalGreen,
                        height: 1.18,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: _LabStatusBadge(
            label: badgeText,
            color: badgeColor,
            icon: labResult.isNormal
                ? Icons.check_circle_rounded
                : Icons.error_rounded,
          ),
        ),
        const SizedBox(height: 12),
        _LabMetaLine(
          icon: Icons.event_available_rounded,
          label: 'Prélevé le',
          value: _formatDate(labResult.sampleDate),
        ),
        if (labResult.dossierNumber != null &&
            labResult.dossierNumber!.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          _LabMetaLine(
            icon: Icons.folder_open_rounded,
            label: 'Dossier LAB',
            value: labResult.dossierNumber!.trim(),
          ),
        ],
        const Divider(height: 24),
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            collapsedIconColor: AppColors.deepHealthBlue,
            iconColor: AppColors.deepHealthBlue,
            title: const Text(
              'Analyses saisies',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.deepHealthBlue,
              ),
            ),
            subtitle: Text(
              analysisBlocks.length <= 1
                  ? '${analysisBlocks.length} résultat'
                  : '${analysisBlocks.length} résultats',
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textSecondary,
              ),
            ),
            children: [
              if (analysisBlocks.isEmpty)
                _LabAnalysisItem(
                  block: _LabAnalysisBlock(
                    title: 'Résultats',
                    lines: [labResult.results.trim()],
                  ),
                )
              else
                for (final block in analysisBlocks)
                  _LabAnalysisItem(block: block),
              if (observations != null && observations.isNotEmpty) ...[
                const SizedBox(height: 6),
                _LabObservationBlock(value: observations),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _labExamTitle(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Bilan laboratoire';
    }
    final separatorIndex = trimmed.indexOf(' - ');
    if (separatorIndex == -1) {
      return trimmed;
    }
    return trimmed.substring(0, separatorIndex).trim();
  }

  String? _labExamDetails(String value) {
    final trimmed = value.trim();
    final separatorIndex = trimmed.indexOf(' - ');
    if (separatorIndex == -1 || separatorIndex + 3 >= trimmed.length) {
      return null;
    }
    return trimmed.substring(separatorIndex + 3).trim();
  }

  List<_LabAnalysisBlock> _labAnalysisBlocks(String value) {
    return value
        .trim()
        .split(RegExp(r'\n\s*\n'))
        .map((block) {
          final lines = block
              .split('\n')
              .map((line) => line.trim())
              .where((line) => line.isNotEmpty)
              .toList(growable: false);
          if (lines.isEmpty) {
            return null;
          }
          return _LabAnalysisBlock(
            title: lines.first,
            lines: lines.skip(1).toList(growable: false),
          );
        })
        .whereType<_LabAnalysisBlock>()
        .toList(growable: false);
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}

class _LabAnalysisBlock {
  const _LabAnalysisBlock({required this.title, required this.lines});

  final String title;
  final List<String> lines;
}

class _LabStatusBadge extends StatelessWidget {
  const _LabStatusBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LabMetaLine extends StatelessWidget {
  const _LabMetaLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 16),
        const SizedBox(width: 7),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.22,
              ),
              children: [
                TextSpan(
                  text: '$label : ',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LabAnalysisItem extends StatelessWidget {
  const _LabAnalysisItem({required this.block});

  final _LabAnalysisBlock block;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              block.title,
              textAlign: TextAlign.left,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
                color: AppColors.deepHealthBlue,
                height: 1.18,
              ),
            ),
            if (block.lines.isNotEmpty) ...[
              const SizedBox(height: 4),
              for (final line in block.lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    line,
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LabObservationBlock extends StatelessWidget {
  const _LabObservationBlock({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Observations du laboratoire',
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.deepHealthBlue,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.left,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
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
