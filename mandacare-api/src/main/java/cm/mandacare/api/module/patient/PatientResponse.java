package cm.mandacare.api.module.patient;

import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

public record PatientResponse(
        UUID id,
        String patientNumber,
        String firstName,
        String lastName,
        String fullName,
        PatientSex sex,
        LocalDate birthDate,
        Integer declaredAge,
        String phone,
        String city,
        String district,
        String emergencyContactName,
        String emergencyContactPhone,
        VisitSummaryResponse latestVisit,
        Instant createdAt
) {
}
