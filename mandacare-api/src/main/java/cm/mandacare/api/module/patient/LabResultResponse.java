package cm.mandacare.api.module.patient;

import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

public record LabResultResponse(
        UUID id,
        String resultNumber,
        String dossierNumber,
        String examType,
        String results,
        String observations,
        LocalDate sampleDate,
        boolean isNormal,
        String status,
        Instant createdAt
) {}
