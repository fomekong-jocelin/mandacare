package cm.mandacare.api.module.patient;

import jakarta.validation.constraints.NotNull;
import java.util.List;

public record CreatePrescriptionRequest(
        @NotNull PrescriptionStatus status,
        List<CreatePrescriptionItemRequest> items
) {}
