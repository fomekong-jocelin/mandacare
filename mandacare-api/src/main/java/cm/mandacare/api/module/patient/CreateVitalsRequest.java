package cm.mandacare.api.module.patient;

import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import java.math.BigDecimal;

public record CreateVitalsRequest(
        @DecimalMin("30.0") @DecimalMax("45.0") @Digits(integer = 2, fraction = 1) BigDecimal temperature,
        @Min(50) @Max(260) Integer systolicPressure,
        @Min(30) @Max(160) Integer diastolicPressure,
        @Min(20) @Max(240) Integer pulse,
        @Min(5) @Max(80) Integer respiratoryRate,
        @Min(50) @Max(100) Integer oxygenSaturation,
        @DecimalMin("1.00") @DecimalMax("300.00") @Digits(integer = 3, fraction = 2) BigDecimal weight,
        @DecimalMin("30.00") @DecimalMax("250.00") @Digits(integer = 3, fraction = 2) BigDecimal height,
        @DecimalMin("0.10") @DecimalMax("999.99") @Digits(integer = 3, fraction = 2) BigDecimal bloodGlucose
) {

    @AssertTrue(message = "Au moins une constante est obligatoire")
    boolean hasMeasurement() {
        return temperature != null
                || systolicPressure != null
                || diastolicPressure != null
                || pulse != null
                || respiratoryRate != null
                || oxygenSaturation != null
                || weight != null
                || height != null
                || bloodGlucose != null;
    }
}
