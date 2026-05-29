package cm.mandacare.api.module.center;

import org.springframework.stereotype.Service;

@Service
class CenterSettingsService {

    private final CenterSettingsProperties properties;

    CenterSettingsService(CenterSettingsProperties properties) {
        this.properties = properties;
    }

    CenterSettingsResponse currentSettings() {
        return new CenterSettingsResponse(
                properties.getName(),
                properties.getSlogan(),
                properties.getCity()
        );
    }
}

