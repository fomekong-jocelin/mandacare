package cm.mandacare.api.module.auth;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record UpdateAuthUserRequest(
        @NotBlank @Size(max = 120) String firstName,
        @NotBlank @Size(max = 120) String lastName,
        @Size(max = 40) String phone,
        @Email @Size(max = 180) String email,
        @NotBlank @Size(min = 3, max = 80) String username,
        @Size(min = 6, max = 120) String password,
        @NotBlank @Pattern(regexp = "ADMIN|MEDECIN|INFIRMIER|CAISSIER|LABORATOIRE|ACCUEIL|AUTRE") String roleCode,
        @NotBlank @Pattern(regexp = "ACTIVE|INACTIVE") String status
) {
}
