package cm.mandacare.api.module.auth;

import java.time.Instant;

record AuthToken(String value, Instant expiresAt) {
}
