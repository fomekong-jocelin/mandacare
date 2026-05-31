enum ActivityHistoryPeriod {
  today('Aujourd’hui'),
  sevenDays('7 jours'),
  thirtyDays('30 jours'),
  all('Tous');

  const ActivityHistoryPeriod(this.label);

  final String label;

  DateTime? get from {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return switch (this) {
      ActivityHistoryPeriod.today => today,
      ActivityHistoryPeriod.sevenDays => today.subtract(
        const Duration(days: 6),
      ),
      ActivityHistoryPeriod.thirtyDays => today.subtract(
        const Duration(days: 29),
      ),
      ActivityHistoryPeriod.all => null,
    };
  }

  DateTime? get to {
    if (this == ActivityHistoryPeriod.all) {
      return null;
    }
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
}

class ConsultationHistoryItem {
  const ConsultationHistoryItem({
    required this.id,
    required this.visitId,
    required this.patientId,
    required this.patientName,
    required this.patientNumber,
    required this.reason,
    required this.diagnosis,
    required this.status,
    required this.decision,
    required this.createdAt,
  });

  final String id;
  final String? visitId;
  final String patientId;
  final String patientName;
  final String patientNumber;
  final String reason;
  final String diagnosis;
  final String status;
  final String decision;
  final DateTime createdAt;
}

class CashDeskHistoryItem {
  const CashDeskHistoryItem({
    required this.invoiceId,
    required this.visitId,
    required this.patientId,
    required this.invoiceNumber,
    required this.patientName,
    required this.netAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.status,
    required this.createdAt,
  });

  final String invoiceId;
  final String? visitId;
  final String patientId;
  final String invoiceNumber;
  final String patientName;
  final double netAmount;
  final double paidAmount;
  final double remainingAmount;
  final String status;
  final DateTime createdAt;
}
