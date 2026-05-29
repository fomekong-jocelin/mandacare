package cm.mandacare.api.module.health;

public record HealthStatusResponse(
        String status,
        String service
) {
}

