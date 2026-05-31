class DashboardTodaySummary {
  const DashboardTodaySummary({
    required this.patientsToday,
    required this.activeQueue,
    required this.waitingQueue,
    required this.consultationQueue,
    required this.cashDeskQueue,
    required this.labQueue,
    required this.consultationsToday,
    required this.pendingExams,
    required this.validatedResults,
    required this.dailyRevenue,
    required this.unpaidInvoices,
  });

  final int patientsToday;
  final int activeQueue;
  final int waitingQueue;
  final int consultationQueue;
  final int cashDeskQueue;
  final int labQueue;
  final int consultationsToday;
  final int pendingExams;
  final int validatedResults;
  final double dailyRevenue;
  final int unpaidInvoices;

  static const empty = DashboardTodaySummary(
    patientsToday: 0,
    activeQueue: 0,
    waitingQueue: 0,
    consultationQueue: 0,
    cashDeskQueue: 0,
    labQueue: 0,
    consultationsToday: 0,
    pendingExams: 0,
    validatedResults: 0,
    dailyRevenue: 0,
    unpaidInvoices: 0,
  );
}
