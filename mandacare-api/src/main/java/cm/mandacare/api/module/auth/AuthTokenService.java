package cm.mandacare.api.module.auth;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Clock;
import java.time.Instant;
import java.util.Base64;
import java.util.Optional;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import org.springframework.stereotype.Service;

@Service
class AuthTokenService {

    private static final String HMAC_ALGORITHM = "HmacSHA256";
    private static final String PAYLOAD_SEPARATOR = "|";
    private final Base64.Encoder encoder = Base64.getUrlEncoder().withoutPadding();
    private final Base64.Decoder decoder = Base64.getUrlDecoder();
    private final AuthProperties properties;
    private final Clock clock;

    AuthTokenService(AuthProperties properties, Clock clock) {
        this.properties = properties;
        this.clock = clock;
    }

    AuthToken issue(String username) {
        Instant expiresAt = Instant.now(clock).plus(properties.tokenTtl());
        String payload = username + PAYLOAD_SEPARATOR + expiresAt.getEpochSecond();
        String encodedPayload = encoder.encodeToString(payload.getBytes(StandardCharsets.UTF_8));
        return new AuthToken(encodedPayload + "." + sign(encodedPayload), expiresAt);
    }

    Optional<String> resolveUsername(String token) {
        String[] parts = token.split("\\.");
        if (parts.length != 2 || !validSignature(parts[0], parts[1])) {
            return Optional.empty();
        }

        String payload = new String(decoder.decode(parts[0]), StandardCharsets.UTF_8);
        String[] values = payload.split("\\|");
        if (values.length != 2 || expired(values[1])) {
            return Optional.empty();
        }
        return Optional.of(values[0]);
    }

    private boolean validSignature(String encodedPayload, String signature) {
        byte[] expected = decoder.decode(sign(encodedPayload));
        byte[] provided = decoder.decode(signature);
        return MessageDigest.isEqual(expected, provided);
    }

    private boolean expired(String epochSeconds) {
        try {
            return Instant.ofEpochSecond(Long.parseLong(epochSeconds)).isBefore(Instant.now(clock));
        } catch (NumberFormatException exception) {
            return true;
        }
    }

    private String sign(String payload) {
        try {
            Mac mac = Mac.getInstance(HMAC_ALGORITHM);
            mac.init(new SecretKeySpec(properties.tokenSecret().getBytes(StandardCharsets.UTF_8), HMAC_ALGORITHM));
            return encoder.encodeToString(mac.doFinal(payload.getBytes(StandardCharsets.UTF_8)));
        } catch (Exception exception) {
            throw new IllegalStateException("Impossible de signer le token.", exception);
        }
    }
}
