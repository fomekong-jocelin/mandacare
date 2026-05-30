package cm.mandacare.api.module.auth;

public record UserProfileResponse(
        String username,
        String displayName,
        String firstName,
        String lastName,
        String phone,
        String email,
        RoleProfileResponse role
) {

    static UserProfileResponse from(AuthUserEntity user) {
        return new UserProfileResponse(
                user.username(),
                user.displayName(),
                user.firstName(),
                user.lastName(),
                user.phone(),
                user.email(),
                RoleProfileResponse.from(user.role())
        );
    }
}
