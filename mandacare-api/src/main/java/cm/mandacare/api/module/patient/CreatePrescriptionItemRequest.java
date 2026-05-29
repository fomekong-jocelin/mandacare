package cm.mandacare.api.module.patient;

public record CreatePrescriptionItemRequest(
        String drugName,
        String form,
        String dosage,
        String frequency,
        String duration,
        Integer quantity,
        String instructions
) {}
