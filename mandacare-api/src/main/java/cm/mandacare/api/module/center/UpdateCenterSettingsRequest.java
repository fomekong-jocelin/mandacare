package cm.mandacare.api.module.center;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record UpdateCenterSettingsRequest(
        @NotBlank @Size(max = 150) String name,
        @NotBlank @Size(max = 200) String slogan,
        @Size(max = 40) String phone,
        @Size(max = 120) String email,
        @NotBlank @Size(max = 100) String city,
        @Size(max = 200) String address,
        @Size(max = 60) String poBox,
        @Size(max = 80) String rccm,
        @Size(max = 80) String taxpayerNumber
) {
}
