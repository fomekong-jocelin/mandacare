package cm.mandacare.api.module.patient;

import java.time.Instant;
import java.util.UUID;

public record VisitSummaryResponse(
        UUID id,
        String reason,
        TargetService targetService,
        VisitStatus status,
        VisitPriority priority,
        Instant arrivalAt
) {
}
