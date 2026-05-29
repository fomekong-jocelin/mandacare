import '../domain/patient_summary.dart';

enum PatientFilter {
  all('Tous'),
  waiting('Attente'),
  urgent('Urgents'),
  cashDesk('Caisse'),
  lab('Labo');

  const PatientFilter(this.label);

  final String label;

  bool accepts(PatientSummary patient) {
    return switch (this) {
      PatientFilter.all => true,
      PatientFilter.waiting => patient.status == PatientStatus.waiting,
      PatientFilter.urgent => patient.priority == PatientPriority.urgent,
      PatientFilter.cashDesk => patient.status == PatientStatus.cashDesk,
      PatientFilter.lab => patient.status == PatientStatus.lab,
    };
  }
}
