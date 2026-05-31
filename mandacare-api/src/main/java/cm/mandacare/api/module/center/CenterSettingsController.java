package cm.mandacare.api.module.center;

import jakarta.validation.Valid;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/settings/center")
@PreAuthorize("isAuthenticated()")
class CenterSettingsController {

    private final CenterSettingsService service;

    CenterSettingsController(CenterSettingsService service) {
        this.service = service;
    }

    @GetMapping
    CenterSettingsResponse currentSettings() {
        return service.currentSettings();
    }

    @PutMapping
    @PreAuthorize("hasRole('ADMIN')")
    CenterSettingsResponse update(@Valid @RequestBody UpdateCenterSettingsRequest request) {
        return service.update(request);
    }
}
