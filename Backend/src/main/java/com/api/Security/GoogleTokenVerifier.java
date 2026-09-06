package com.api.Security;

import java.time.Instant;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

import com.api.exception.InvalidCredentialsException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

/**
 * Verifies a Google ID token by calling Google's public {@code tokeninfo}
 * endpoint (no extra dependency, no JWKS handling). Suitable for a mobile
 * client that obtained the token via the Google Sign-In SDK.
 */
@Component
public class GoogleTokenVerifier {

    private static final Logger log = LoggerFactory.getLogger(GoogleTokenVerifier.class);
    private static final ObjectMapper MAPPER = new ObjectMapper();

    private final RestClient rest = RestClient.create();
    private final String clientId;

    public GoogleTokenVerifier(@Value("${app.google.client-id:}") String clientId) {
        this.clientId = clientId == null ? "" : clientId.trim();
    }

    /** Google account extracted from a verified ID token. */
    public record GooglePrincipal(String email, String givenName, String familyName) {
    }

    public GooglePrincipal verify(String idToken) {
        if (idToken == null || idToken.isBlank()) {
            throw new InvalidCredentialsException("idToken is required");
        }

        JsonNode claims;
        try {
            // Fetch as String + parse with our own (Jackson 2) mapper - the
            // RestClient converter is Jackson 3 and cannot bind com.fasterxml.
            String body = rest.get()
                    .uri("https://oauth2.googleapis.com/tokeninfo?id_token={t}", idToken)
                    .retrieve()
                    .body(String.class);
            claims = MAPPER.readTree(body);
        } catch (RuntimeException | java.io.IOException e) {
            throw new InvalidCredentialsException("Google token rejected: " + e.getMessage());
        }
        if (claims == null || claims.hasNonNull("error")) {
            throw new InvalidCredentialsException("Invalid Google ID token");
        }

        String aud = claims.path("aud").asText("");
        if (clientId.isEmpty()) {
            log.warn("app.google.client-id is not set - skipping audience check (dev only)");
        } else if (!clientId.equals(aud)) {
            throw new InvalidCredentialsException("Google ID token audience mismatch");
        }

        long exp = claims.path("exp").asLong(0);
        if (exp > 0 && exp < Instant.now().getEpochSecond()) {
            throw new InvalidCredentialsException("Google ID token has expired");
        }

        if (!"true".equalsIgnoreCase(claims.path("email_verified").asText("false"))) {
            throw new InvalidCredentialsException("Google account email is not verified");
        }

        String email = claims.path("email").asText("");
        if (email.isBlank()) {
            throw new InvalidCredentialsException("Google ID token has no email");
        }

        return new GooglePrincipal(
                email.toLowerCase(),
                firstNonBlank(claims.path("given_name").asText(""), claims.path("name").asText("")),
                claims.path("family_name").asText(""));
    }

    private static String firstNonBlank(String a, String b) {
        return (a != null && !a.isBlank()) ? a : b;
    }
}
