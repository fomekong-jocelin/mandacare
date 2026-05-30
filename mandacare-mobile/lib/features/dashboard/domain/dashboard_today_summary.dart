class DashboardTodaySummary {
  const DashboardTodaySummary({
    required this.patientsToday,
    required this.consultationsToday,
    required this.pendingExams,
    required this.validatedResults,
    required this.dailyRevenue,
    required this.unpaidInvoices,
  });

  final int patientsToday;
  final int consultationsToday;
  final int pendingExams;
  final int validatedResults;
  final double dailyRevenue;
  final int unpaidInvoices;

  static const empty = DashboardTodaySummary(
    patientsToday: 0,
    consultationsToday: 0,
    pendingExams: 0,
    validatedResults: 0,
    dailyRevenue: 0,
    unpaidInvoices: 0,
  );
}
