class DailyReport {
  const DailyReport({
    required this.totalPatientsToday,
    required this.patientsByStatus,
    required this.revenueByPaymentMode,
    required this.totalRevenue,
    required this.topPrescribedExams,
  });

  final int totalPatientsToday;
  final Map<String, int> patientsByStatus;
  final Map<String, double> revenueByPaymentMode;
  final double totalRevenue;
  final Map<String, int> topPrescribedExams;

  factory DailyReport.fromJson(Map<String, dynamic> json) {
    final statusMap = Map<String, int>.from(json['patientsByStatus'] ?? {});
    
    final rawRevenueMap = json['revenueByPaymentMode'] as Map<String, dynamic>? ?? {};
    final revenueMap = rawRevenueMap.map((key, value) => MapEntry(key, (value as num).toDouble()));

    final examsMap = Map<String, int>.from(json['topPrescribedExams'] ?? {});

    return DailyReport(
      totalPatientsToday: json['totalPatientsToday'] as int? ?? 0,
      patientsByStatus: statusMap,
      revenueByPaymentMode: revenueMap,
      totalRevenue: (json['totalRevenue'] as num? ?? 0.0).toDouble(),
      topPrescribedExams: examsMap,
    );
  }
}
