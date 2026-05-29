package cm.mandacare.api.module.patient;

import java.time.Instant;
import java.util.UUID;

public record ConsultationResponse(
        UUID id,
        UUID visitId,
        UUID patientId,
        String reason,
        String symptoms,
        String clinicalExam,
        String diagnosis,
        String advice,
        ConsultationStatus status,
        ConsultationDecision decision,
        VisitStatus visitStatus,
        Instant validatedAt,
        Instant createdAt
) {
}
