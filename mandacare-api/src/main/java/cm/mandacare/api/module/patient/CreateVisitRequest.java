package cm.mandacare.api.module.patient;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record CreateVisitRequest(
        @NotBlank @Size(max = 500) String reason,
        @NotNull VisitPriority priority,
        TargetService targetService
) {
}
