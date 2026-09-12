package com.api.Security;

import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Base64;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;

/**
 * Minimal, dependency-free HS256 JSON Web Token helper.
 *
 * <p>Signs/verifies with {@code HmacSHA256} from the JDK and (de)serialises the
 * payload with the Jackson {@link ObjectMapper} that Spring Boot already puts on
 * the classpath, so no extra library is required.
 */
@Service
public class JwtService {

    private static final String HEADER_JSON = "{\"alg\":\"HS256\",\"typ\":\"JWT\"}";
    private static final Base64.Encoder B64 = Base64.getUrlEncoder().withoutPadding();
    private static final Base64.Decoder B64D = Base64.getUrlDecoder();
    private static final ObjectMapper MAPPER = new ObjectMapper();

    private final byte[] secret;
    private final long expirationSeconds;

    public JwtService(
            @Value("${app.jwt.secret}") String secret,
            @Value("${app.jwt.expiration-seconds:86400}") long expirationSeconds) {
        if (secret == null || secret.getBytes(StandardCharsets.UTF_8).length < 32) {
            throw new IllegalStateException(
                    "app.jwt.secret must be set and at least 32 bytes long");
        }
        this.secret = secret.getBytes(StandardCharsets.UTF_8);
        this.expirationSeconds = expirationSeconds;
    }

    /** Build a signed token whose subject is the user's email. */
    public String generateToken(String email) {
        long now = Instant.now().getEpochSecond();

        ObjectNode payload = MAPPER.createObjectNode();
        payload.put("sub", email);
        payload.put("iat", now);
        payload.put("exp", now + expirationSeconds);

        String unsigned = encode(HEADER_JSON.getBytes(StandardCharsets.UTF_8))
                + "." + encode(writeJson(payload));
        return unsigned + "." + encode(hmac(unsigned));
    }

    /**
     * Return the token subject (email) when the signature is valid and the token
     * has not expired; otherwise {@code null}.
     */
    public String extractEmail(String token) {
        if (token == null) {
            return null;
        }
        String[] parts = token.split("\\.");
        if (parts.length != 3) {
            return null;
        }
        String unsigned = parts[0] + "." + parts[1];
        if (!constantTimeEquals(encode(hmac(unsigned)), parts[2])) {
            return null;
        }
        try {
            JsonNode claims = MAPPER.readTree(B64D.decode(parts[1]));
            long exp = claims.path("exp").asLong(0);
            if (exp > 0 && exp < Instant.now().getEpochSecond()) {
                return null;
            }
            String sub = claims.path("sub").asText(null);
            return (sub == null || sub.isBlank()) ? null : sub;
        } catch (RuntimeException | java.io.IOException e) {
            return null;
        }
    }

    public boolean isValid(String token) {
        return extractEmail(token) != null;
    }

    private byte[] hmac(String data) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(secret, "HmacSHA256"));
            return mac.doFinal(data.getBytes(StandardCharsets.UTF_8));
        } catch (java.security.GeneralSecurityException e) {
            throw new IllegalStateException("Unable to sign JWT", e);
        }
    }

    private static String encode(byte[] bytes) {
        return B64.encodeToString(bytes);
    }

    private static byte[] writeJson(JsonNode node) {
        try {
            return MAPPER.writeValueAsBytes(node);
        } catch (com.fasterxml.jackson.core.JsonProcessingException e) {
            throw new IllegalStateException("Unable to serialise JWT claims", e);
        }
    }

    private static boolean constantTimeEquals(String a, String b) {
        if (a.length() != b.length()) {
            return false;
        }
        int result = 0;
        for (int i = 0; i < a.length(); i++) {
            result |= a.charAt(i) ^ b.charAt(i);
        }
        return result == 0;
    }
}
