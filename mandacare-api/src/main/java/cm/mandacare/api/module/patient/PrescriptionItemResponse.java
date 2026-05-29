package cm.mandacare.api.module.patient;

import java.util.UUID;

public record PrescriptionItemResponse(
        UUID id,
        String drugName,
        String form,
        String dosage,
        String frequency,
        String duration,
        Integer quantity,
        String instructions
) {}
