package cm.mandacare.api.module.patient;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

public record VitalsResponse(
        UUID id,
        UUID visitId,
        UUID patientId,
        BigDecimal temperature,
        Integer systolicPressure,
        Integer diastolicPressure,
        Integer pulse,
        Integer respiratoryRate,
        Integer oxygenSaturation,
        BigDecimal weight,
        BigDecimal height,
        BigDecimal bmi,
        BigDecimal bloodGlucose,
        Instant createdAt
) {
}
