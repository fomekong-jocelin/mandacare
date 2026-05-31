package cm.mandacare.api.module.patient;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import java.math.BigDecimal;

public record CreatePharmacyItemRequest(
    @NotBlank String code,
    @NotBlank String label,
    String dosage,
    @NotNull @Positive BigDecimal price,
    Integer alertThreshold
) {}
