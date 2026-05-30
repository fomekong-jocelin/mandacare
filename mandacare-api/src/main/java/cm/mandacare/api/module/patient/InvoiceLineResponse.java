package cm.mandacare.api.module.patient;

import java.math.BigDecimal;

public record InvoiceLineResponse(
        String type,
        String label,
        BigDecimal price,
        int quantity
) {
}
