package cm.mandacare.api.module.patient;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.util.UUID;

public record ShareLogRequest(
    @NotBlank String entityType,
    @NotNull UUID entityId,
    @NotBlank String channel,
    boolean consent
) {}
