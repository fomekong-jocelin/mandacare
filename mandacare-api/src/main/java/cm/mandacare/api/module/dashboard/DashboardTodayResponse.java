package cm.mandacare.api.module.dashboard;

import java.math.BigDecimal;

public record DashboardTodayResponse(
        int patientsToday,
        int consultationsToday,
        int pendingExams,
        int validatedResults,
        BigDecimal dailyRevenue,
        int unpaidInvoices
) {
}

