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
    return DailyReport(
      totalPatientsToday: _int(json['totalPatientsToday']),
      patientsByStatus: _statusMap(json['patientsByStatus']),
      revenueByPaymentMode: _doubleMap(json['revenueByPaymentMode']),
      totalRevenue: _double(json['totalRevenue']),
      topPrescribedExams: _intMap(json['topPrescribedExams']),
    );
  }

  static Map<String, int> _statusMap(Object? value) {
    final raw = _intMap(value);
    return raw.map((key, value) => MapEntry(_statusKey(key), value));
  }

  static String _statusKey(String key) {
    return switch (key) {
      'WAITING' => 'waiting',
      'IN_CONSULTATION' => 'inConsultation',
      'CASH_DESK' => 'cashDesk',
      'LAB' => 'lab',
      'RELEASED' => 'released',
      _ => key,
    };
  }

  static Map<String, int> _intMap(Object? value) {
    if (value is! Map) {
      return const {};
    }
    return value.map((key, value) => MapEntry(key.toString(), _int(value)));
  }

  static Map<String, double> _doubleMap(Object? value) {
    if (value is! Map) {
      return const {};
    }
    return value.map((key, value) => MapEntry(key.toString(), _double(value)));
  }

  static int _int(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _double(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}
