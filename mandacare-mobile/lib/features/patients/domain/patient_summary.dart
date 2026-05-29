enum PatientStatus {
  waiting('En attente'),
  inConsultation('Consultation'),
  cashDesk('Caisse'),
  lab('Labo'),
  released('Sorti');

  const PatientStatus(this.label);

  final String label;
}

enum PatientPriority {
  normal('Standard'),
  watch('Surveillance'),
  urgent('Urgent');

  const PatientPriority(this.label);

  final String label;
}

class PatientSummary {
  const PatientSummary({
    this.id,
    this.patientNumber,
    this.latestVisitId,
    required this.fullName,
    required this.sexAge,
    required this.phoneNumber,
    required this.reason,
    required this.lastVisit,
    required this.status,
    required this.priority,
  });

  final String? id;
  final String? patientNumber;
  final String? latestVisitId;
  final String fullName;
  final String sexAge;
  final String phoneNumber;
  final String reason;
  final String lastVisit;
  final PatientStatus status;
  final PatientPriority priority;

  String get initials {
    final words = fullName.trim().split(RegExp(r'\s+'));
    if (words.length == 1) {
      final endIndex = words.first.length < 2 ? words.first.length : 2;
      return words.first.substring(0, endIndex).toUpperCase();
    }
    return words.take(2).map((word) => word.substring(0, 1)).join();
  }

  bool matchesQuery(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return true;
    }

    final searchable = [
      fullName,
      phoneNumber,
      reason,
      status.label,
      priority.label,
    ].join(' ').toLowerCase();
    return searchable.contains(normalizedQuery);
  }
}
