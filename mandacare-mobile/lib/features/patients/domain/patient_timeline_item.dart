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
    this.labResult,
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
  final PatientLabResultSummary? labResult;
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
    this.hasPrescription = false,
  });

  final String id;
  final String symptoms;
  final String clinicalExam;
  final String diagnosis;
  final ConsultationDecision decision;
  final String? advice;
  final String status;
  final DateTime createdAt;
  final bool hasPrescription;
}

class PatientLabResultSummary {
  const PatientLabResultSummary({
    required this.id,
    required this.resultNumber,
    required this.dossierNumber,
    required this.examType,
    required this.results,
    required this.observations,
    required this.sampleDate,
    required this.isNormal,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String resultNumber;
  final String? dossierNumber;
  final String examType;
  final String results;
  final String? observations;
  final DateTime sampleDate;
  final bool isNormal;
  final String status;
  final DateTime createdAt;
}
