package cm.mandacare.api.module.auth;

public record RoleProfileResponse(
        String code,
        String label,
        String description
) {

    static RoleProfileResponse from(RoleEntity role) {
        return new RoleProfileResponse(role.code(), role.label(), role.description());
    }
}
