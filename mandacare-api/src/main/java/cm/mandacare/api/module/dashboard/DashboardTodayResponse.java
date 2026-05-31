package cm.mandacare.api.module.dashboard;

import java.math.BigDecimal;

public record DashboardTodayResponse(
        int patientsToday,
        int activeQueue,
        int waitingQueue,
        int consultationQueue,
        int cashDeskQueue,
        int labQueue,
        int consultationsToday,
        int pendingExams,
        int validatedResults,
        BigDecimal dailyRevenue,
        int unpaidInvoices
) {
}
