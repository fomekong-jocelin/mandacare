package cm.mandacare.api.module.patient;

import java.math.BigDecimal;
import java.util.UUID;

public record BenefitResponse(
        UUID id,
        String code,
        String name,
        String category,
        BigDecimal price,
        boolean active
) {
}
