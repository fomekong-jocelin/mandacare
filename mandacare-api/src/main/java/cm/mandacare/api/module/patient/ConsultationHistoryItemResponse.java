package cm.mandacare.api.module.patient;

import java.time.Instant;
import java.util.UUID;

public record ConsultationHistoryItemResponse(
        UUID id,
        UUID visitId,
        UUID patientId,
        String patientNumber,
        String patientName,
        String reason,
        String diagnosis,
        ConsultationStatus status,
        ConsultationDecision decision,
        boolean hasPrescription,
        Instant createdAt,
        Instant validatedAt
) {
}
