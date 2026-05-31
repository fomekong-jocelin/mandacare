package cm.mandacare.api.module.patient;

import java.math.BigDecimal;
import java.util.Map;

public record ReportResponse(
    long totalPatientsToday,
    Map<String, Long> patientsByStatus,
    Map<String, BigDecimal> revenueByPaymentMode,
    BigDecimal totalRevenue,
    Map<String, Long> topPrescribedExams
) {}
