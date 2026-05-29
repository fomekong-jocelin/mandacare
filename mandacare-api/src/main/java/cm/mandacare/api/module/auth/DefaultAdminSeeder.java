package cm.mandacare.api.module.auth;

import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

@Component
class DefaultAdminSeeder implements ApplicationRunner {

    private final AuthProperties properties;
    private final RoleRepository roles;
    private final AuthUserRepository users;
    private final PasswordEncoder passwordEncoder;

    DefaultAdminSeeder(
            AuthProperties properties,
            RoleRepository roles,
            AuthUserRepository users,
            PasswordEncoder passwordEncoder
    ) {
        this.properties = properties;
        this.roles = roles;
        this.users = users;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        AuthProperties.DefaultAdmin admin = properties.defaultAdmin();
        if (!admin.enabled() || users.existsByUsernameIgnoreCase(admin.username())) {
            return;
        }

        RoleEntity adminRole = roles.findByCode("ADMIN").orElseGet(() -> roles.save(RoleEntity.admin()));
        String encodedPassword = passwordEncoder.encode(admin.password());
        users.save(AuthUserEntity.admin(adminRole, admin, encodedPassword));
    }
}
