import '../../consultations/domain/consultation_decision.dart';
import 'patient_summary.dart';
import 'vitals_summary.dart';

class PatientTimelineItem {
  const PatientTimelineItem({
    required this.visitId,
    required this.reason,
    required this.targetService,
    required this.status,
    required this.priority,
    required this.arrivalAt,
    this.closedAt,
    this.vitals,
    this.consultation,
  });

  final String visitId;
  final String reason;
  final String targetService;
  final PatientStatus status;
  final PatientPriority priority;
  final DateTime arrivalAt;
  final DateTime? closedAt;
  final VitalsSummary? vitals;
  final PatientConsultationSummary? consultation;
}

class PatientConsultationSummary {
  const PatientConsultationSummary({
    required this.id,
    required this.symptoms,
    required this.clinicalExam,
    required this.diagnosis,
    required this.decision,
    this.advice,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String symptoms;
  final String clinicalExam;
  final String diagnosis;
  final ConsultationDecision decision;
  final String? advice;
  final String status;
  final DateTime createdAt;
}
