package cm.mandacare.api.module.patient;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;

public record CashDeskPaymentRequest(
        @NotNull @DecimalMin("1.00") BigDecimal amount,
        @NotNull PaymentMode mode,
        @Size(max = 120) String reference
) {
}
