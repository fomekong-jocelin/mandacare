package cm.mandacare.api.module.patient;

import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PastOrPresent;
import jakarta.validation.constraints.Size;
import java.time.LocalDate;

public record CreatePatientRequest(
        @NotBlank @Size(max = 120) String firstName,
        @NotBlank @Size(max = 120) String lastName,
        @NotNull PatientSex sex,
        @PastOrPresent LocalDate birthDate,
        @Min(0) @Max(130) Integer declaredAge,
        @NotBlank @Size(max = 40) String phone,
        @Size(max = 120) String city,
        @Size(max = 120) String district,
        @Size(max = 180) String emergencyContactName,
        @Size(max = 40) String emergencyContactPhone,
        @NotBlank @Size(max = 500) String arrivalReason,
        @NotNull VisitPriority priority,
        TargetService targetService
) {

    @AssertTrue(message = "birthDate ou declaredAge est obligatoire")
    boolean hasAgeInformation() {
        return birthDate != null || declaredAge != null;
    }
}
