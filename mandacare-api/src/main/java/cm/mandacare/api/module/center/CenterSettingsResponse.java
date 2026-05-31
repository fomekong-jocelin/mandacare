package cm.mandacare.api.module.center;

public record CenterSettingsResponse(
        String name,
        String slogan,
        String phone,
        String email,
        String city,
        String address,
        String poBox,
        String rccm,
        String taxpayerNumber
) {
}
