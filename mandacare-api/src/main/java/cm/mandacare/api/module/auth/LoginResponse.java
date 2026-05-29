package cm.mandacare.api.module.auth;

import java.time.Instant;

public record LoginResponse(
        String accessToken,
        String tokenType,
        Instant expiresAt,
        String username,
        String displayName
) {
}
