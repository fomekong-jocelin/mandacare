class ConsultationHistoryItem {
  const ConsultationHistoryItem({
    required this.id,
    required this.visitId,
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
  final String invoiceNumber;
  final String patientName;
  final double netAmount;
  final double paidAmount;
  final double remainingAmount;
  final String status;
  final DateTime createdAt;
}
