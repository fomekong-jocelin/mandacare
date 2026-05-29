package cm.mandacare.api.module.auth;

import cm.mandacare.api.common.error.BusinessException;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
class AuthService {

    private final AuthUserRepository users;
    private final PasswordEncoder passwordEncoder;
    private final AuthTokenService tokens;

    AuthService(AuthUserRepository users, PasswordEncoder passwordEncoder, AuthTokenService tokens) {
        this.users = users;
        this.passwordEncoder = passwordEncoder;
        this.tokens = tokens;
    }

    @Transactional
    LoginResponse login(LoginRequest request) {
        AuthUserEntity user = users.findByUsernameIgnoreCase(request.username().trim())
                .orElseThrow(this::invalidCredentials);
        if (!user.active() || !passwordEncoder.matches(request.password(), user.passwordHash())) {
            throw invalidCredentials();
        }

        user.markLoggedIn();
        AuthToken token = tokens.issue(user.username());
        return new LoginResponse(
                token.value(),
                "Bearer",
                token.expiresAt(),
                user.username(),
                user.displayName()
        );
    }

    private BusinessException invalidCredentials() {
        return new BusinessException(
                "AUTH_INVALID_CREDENTIALS",
                "Identifiants invalides.",
                HttpStatus.UNAUTHORIZED
        );
    }
}
