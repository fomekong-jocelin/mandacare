package cm.mandacare.api.module.center;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/settings/center")
class CenterSettingsController {

    private final CenterSettingsService service;

    CenterSettingsController(CenterSettingsService service) {
        this.service = service;
    }

    @GetMapping
    CenterSettingsResponse currentSettings() {
        return service.currentSettings();
    }
}

