package cm.mandacare.api.module.patient;

import java.time.Instant;
import java.util.UUID;

public record PatientTimelineItemResponse(
        UUID visitId,
        String reason,
        TargetService targetService,
        VisitStatus status,
        VisitPriority priority,
        Instant arrivalAt,
        Instant closedAt,
        VitalsResponse vitals,
        ConsultationResponse consultation
) {}
