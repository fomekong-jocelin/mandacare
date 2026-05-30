package cm.mandacare.api.module.auth;

import java.time.Instant;
import java.util.UUID;

public record AuthUserResponse(
        UUID id,
        String username,
        String displayName,
        String firstName,
        String lastName,
        String phone,
        String email,
        String status,
        RoleProfileResponse role,
        Instant lastLoginAt,
        Instant createdAt,
        Instant updatedAt
) {

    static AuthUserResponse from(AuthUserEntity user) {
        return new AuthUserResponse(
                user.id(),
                user.username(),
                user.displayName(),
                user.firstName(),
                user.lastName(),
                user.phone(),
                user.email(),
                user.status(),
                RoleProfileResponse.from(user.role()),
                user.lastLoginAt(),
                user.createdAt(),
                user.updatedAt()
        );
    }
}
