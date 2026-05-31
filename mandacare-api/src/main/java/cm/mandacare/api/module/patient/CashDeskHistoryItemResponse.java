package cm.mandacare.api.module.patient;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

public record CashDeskHistoryItemResponse(
        UUID invoiceId,
        UUID visitId,
        UUID patientId,
        String invoiceNumber,
        String patientName,
        BigDecimal netAmount,
        BigDecimal paidAmount,
        BigDecimal remainingAmount,
        String status,
        Instant createdAt
) {
}
