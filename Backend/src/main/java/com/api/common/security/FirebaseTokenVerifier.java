package com.api.common.security;

import com.api.common.exception.InvalidCredentialsException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

import java.util.Map;

@Component
public class FirebaseTokenVerifier {

    private static final Logger log = LoggerFactory.getLogger(FirebaseTokenVerifier.class);
    private static final ObjectMapper MAPPER = new ObjectMapper();

    private final RestClient rest = RestClient.create();
    private final String apiKey;

    public FirebaseTokenVerifier(@Value("${app.firebase.api-key:AIzaSyDJj4vfUXUUZTBGlX-wuC0-mYRC-jlUG3M}") String apiKey) {
        this.apiKey = apiKey == null ? "" : apiKey.trim();
    }

    public record FirebasePrincipal(String uid, String phoneNumber) {}

    public FirebasePrincipal verify(String idToken) {
        if (idToken == null || idToken.isBlank()) {
            throw new InvalidCredentialsException("Firebase idToken is required");
        }

        try {
            String body = rest.post()
                    .uri("https://identitytoolkit.googleapis.com/v1/accounts:lookup?key={apiKey}", apiKey)
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(Map.of("idToken", idToken))
                    .retrieve()
                    .body(String.class);

            JsonNode root = MAPPER.readTree(body);
            if (root == null || !root.hasNonNull("users") || root.path("users").isEmpty()) {
                throw new InvalidCredentialsException("Invalid or expired Firebase token");
            }

            JsonNode userNode = root.path("users").get(0);
            String uid = userNode.path("localId").asText("");
            String phoneNumber = userNode.path("phoneNumber").asText("");

            if (phoneNumber.isBlank()) {
                throw new InvalidCredentialsException("Firebase user has no verified phone number");
            }

            return new FirebasePrincipal(uid, phoneNumber);
        } catch (RuntimeException | java.io.IOException e) {
            log.warn("Firebase token verification failed: {}", e.getMessage());
            throw new InvalidCredentialsException("Firebase authentication failed: " + e.getMessage());
        }
    }
}
