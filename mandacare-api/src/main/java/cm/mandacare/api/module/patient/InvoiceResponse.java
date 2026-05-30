package cm.mandacare.api.module.patient;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

public record InvoiceResponse(
        UUID id,
        String invoiceNumber,
        BigDecimal totalAmount,
        BigDecimal discount,
        BigDecimal netAmount,
        BigDecimal paidAmount,
        BigDecimal remainingAmount,
        String status,
        Instant createdAt,
        List<InvoiceLineResponse> items
) {}
