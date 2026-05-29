package cm.mandacare.api.module.auth;

import java.time.Duration;
import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "mandacare.auth")
public record AuthProperties(
        String tokenSecret,
        Duration tokenTtl,
        DefaultAdmin defaultAdmin
) {

    public AuthProperties {
        if (tokenSecret == null || tokenSecret.isBlank()) {
            tokenSecret = "mandacare-local-development-token-secret-change-me";
        }
        if (tokenTtl == null) {
            tokenTtl = Duration.ofHours(12);
        }
        if (defaultAdmin == null) {
            defaultAdmin = new DefaultAdmin(true, "admin", "admin123", "Dr", "Manda");
        }
    }

    public record DefaultAdmin(
            boolean enabled,
            String username,
            String password,
            String firstName,
            String lastName
    ) {
    }
}
