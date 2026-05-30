package cm.mandacare.api.module.auth;

import cm.mandacare.api.common.error.BusinessException;
import java.util.List;
import java.util.Locale;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
class AuthUserAdministrationService {

    private final AuthUserRepository users;
    private final RoleRepository roles;
    private final PasswordEncoder passwordEncoder;

    AuthUserAdministrationService(
            AuthUserRepository users,
            RoleRepository roles,
            PasswordEncoder passwordEncoder
    ) {
        this.users = users;
        this.roles = roles;
        this.passwordEncoder = passwordEncoder;
    }

    @Transactional(readOnly = true)
    List<RoleProfileResponse> listRoles() {
        return roles.findAllByOrderByLabelAsc()
                .stream()
                .map(RoleProfileResponse::from)
                .toList();
    }

    @Transactional(readOnly = true)
    List<AuthUserResponse> listUsers() {
        return users.findAllByOrderByCreatedAtDesc()
                .stream()
                .map(AuthUserResponse::from)
                .toList();
    }

    @Transactional
    AuthUserResponse create(CreateAuthUserRequest request) {
        String username = normalizeRequired(request.username());
        if (users.existsByUsernameIgnoreCase(username)) {
            throw new BusinessException(
                    "AUTH_USER_USERNAME_ALREADY_EXISTS",
                    "Ce nom d'utilisateur existe déjà.",
                    HttpStatus.CONFLICT
            );
        }

        RoleEntity role = findRole(request.roleCode());
        AuthUserEntity user = AuthUserEntity.staff(
                role,
                normalizeRequired(request.firstName()),
                normalizeRequired(request.lastName()),
                normalizeOptional(request.phone()),
                normalizeOptional(request.email()),
                username,
                passwordEncoder.encode(request.password())
        );
        return AuthUserResponse.from(users.save(user));
    }

    @Transactional
    AuthUserResponse update(UUID id, UpdateAuthUserRequest request) {
        AuthUserEntity user = users.findWithRoleById(id).orElseThrow(this::userNotFound);
        String username = normalizeRequired(request.username());
        if (users.existsByUsernameIgnoreCaseAndIdNot(username, id)) {
            throw new BusinessException(
                    "AUTH_USER_USERNAME_ALREADY_EXISTS",
                    "Ce nom d'utilisateur existe déjà.",
                    HttpStatus.CONFLICT
            );
        }

        RoleEntity role = findRole(request.roleCode());
        user.updateProfile(
                role,
                normalizeRequired(request.firstName()),
                normalizeRequired(request.lastName()),
                normalizeOptional(request.phone()),
                normalizeOptional(request.email()),
                username,
                request.status()
        );
        if (request.password() != null && !request.password().isBlank()) {
            user.changePassword(passwordEncoder.encode(request.password()));
        }
        return AuthUserResponse.from(user);
    }

    private RoleEntity findRole(String roleCode) {
        String code = normalizeRequired(roleCode).toUpperCase(Locale.ROOT);
        return roles.findByCode(code).orElseThrow(() -> new BusinessException(
                "AUTH_ROLE_NOT_FOUND",
                "Le rôle demandé est introuvable.",
                HttpStatus.BAD_REQUEST
        ));
    }

    private BusinessException userNotFound() {
        return new BusinessException(
                "AUTH_USER_NOT_FOUND",
                "Utilisateur introuvable.",
                HttpStatus.NOT_FOUND
        );
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
