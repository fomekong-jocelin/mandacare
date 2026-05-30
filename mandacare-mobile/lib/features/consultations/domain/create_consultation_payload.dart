import 'consultation_decision.dart';

class CreateConsultationPayload {
  const CreateConsultationPayload({
    required this.symptoms,
    required this.clinicalExam,
    required this.diagnosis,
    required this.advice,
    required this.decision,
    required this.status,
    this.correctionMotif,
    this.prescribedExams,
  });

  final String symptoms;
  final String clinicalExam;
  final String diagnosis;
  final String advice;
  final ConsultationDecision decision;
  final String status;
  final String? correctionMotif;
  final List<String>? prescribedExams;

  Map<String, dynamic> toJson() {
    return {
      'symptoms': symptoms.trim(),
      'clinicalExam': clinicalExam.trim(),
      'diagnosis': diagnosis.trim(),
      'advice': advice.trim().isEmpty ? null : advice.trim(),
      'decision': decision.apiValue,
      'status': status,
      'correctionMotif': correctionMotif?.trim(),
      'prescribedExams': prescribedExams,
    }..removeWhere((_, value) => value == null);
  }
}
