package cm.mandacare.api.module.auth;

import cm.mandacare.api.common.error.BusinessException;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
class ProfileService {

    private final AuthUserRepository users;
    private final PasswordEncoder passwordEncoder;

    ProfileService(AuthUserRepository users, PasswordEncoder passwordEncoder) {
        this.users = users;
        this.passwordEncoder = passwordEncoder;
    }

    @Transactional(readOnly = true)
    public UserProfileResponse getProfile() {
        AuthUserEntity user = getCurrentUser();
        return UserProfileResponse.from(user);
    }

    @Transactional
    public UserProfileResponse updateProfile(UpdateProfileRequest request) {
        AuthUserEntity user = getCurrentUser();

        // Update profile fields (keeping role, username, and status unchanged)
        user.updateProfile(
                user.role(),
                normalizeRequired(request.firstName()),
                normalizeRequired(request.lastName()),
                normalizeOptional(request.phone()),
                normalizeOptional(request.email()),
                user.username(),
                user.status()
        );

        if (request.password() != null && !request.password().isBlank()) {
            user.changePassword(passwordEncoder.encode(request.password()));
        }

        users.save(user);
        return UserProfileResponse.from(user);
    }

    private AuthUserEntity getCurrentUser() {
        var auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated() || "anonymousUser".equals(auth.getName())) {
            throw new BusinessException(
                    "AUTH_UNAUTHORIZED",
                    "Non authentifié.",
                    HttpStatus.UNAUTHORIZED
            );
        }
        String username = auth.getName();
        return users.findByUsernameIgnoreCase(username)
                .orElseThrow(() -> new BusinessException(
                        "AUTH_USER_NOT_FOUND",
                        "Utilisateur introuvable.",
                        HttpStatus.NOT_FOUND
                ));
    }

    private String normalizeRequired(String value) {
        return value.trim();
    }

    private String normalizeOptional(String value) {
        if (value == null || value.trim().isEmpty()) {
            return null;
        }
        return value.trim();
    }
}
