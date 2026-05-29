enum ConsultationDecision {
  keepInConsultation('Continuer', 'KEEP_IN_CONSULTATION'),
  sendToLab('Labo', 'SEND_TO_LAB'),
  releasePatient('Sortie', 'RELEASE_PATIENT');

  const ConsultationDecision(this.label, this.apiValue);

  final String label;
  final String apiValue;
}
