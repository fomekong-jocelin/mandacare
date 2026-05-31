package cm.mandacare.api.module.patient;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record StockAdjustmentRequest(
    @NotNull Integer quantity,
    @NotBlank String reason
) {}
