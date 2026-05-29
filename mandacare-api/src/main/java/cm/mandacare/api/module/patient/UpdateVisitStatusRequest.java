package cm.mandacare.api.module.patient;

import jakarta.validation.constraints.NotNull;

public record UpdateVisitStatusRequest(@NotNull VisitStatus status) {
}
