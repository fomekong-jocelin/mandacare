package cm.mandacare.api.module.patient;

import java.math.BigDecimal;
import java.util.UUID;

public record PharmacyItemResponse(
    UUID id,
    String code,
    String label,
    String dosage,
    BigDecimal price,
    Integer stockQuantity,
    Integer alertThreshold,
    boolean critical
) {}
