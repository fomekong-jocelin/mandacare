package cm.mandacare.api.module.patient;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.time.LocalDate;

public record CreateLabResultRequest(
        @NotBlank
        @Size(max = 180)
        String examType,

        String results,

        String observations,

        LocalDate sampleDate,

        @Size(max = 60)
        String dossierNumber,

        boolean isNormal
) {}
