package cm.mandacare.api.module.auth;

import jakarta.validation.Valid;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/auth/profile")
@PreAuthorize("isAuthenticated()")
class ProfileController {

    private final ProfileService service;

    ProfileController(ProfileService service) {
        this.service = service;
    }

    @GetMapping
    UserProfileResponse getProfile() {
        return service.getProfile();
    }

    @PutMapping
    UserProfileResponse updateProfile(@Valid @RequestBody UpdateProfileRequest request) {
        return service.updateProfile(request);
    }
}
