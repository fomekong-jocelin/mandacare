package cm.mandacare.api.module.patient;

import java.math.BigDecimal;
import java.util.List;

public record InvoicePreviewResponse(
        BigDecimal totalAmount,
        BigDecimal discount,
        BigDecimal netAmount,
        List<InvoiceLineResponse> items
) {
}
