package com.api.Service.sms;

import java.time.Duration;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.MediaType;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestClient;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

/**
 * Sends a real SMS via <a href="https://textbelt.com">TextBelt</a> - a
 * no-signup HTTP SMS API. {@code POST https://textbelt.com/text} with a
 * form-encoded body {@code phone, message, key}.
 *
 * <p>Use {@code key=textbelt} for the free tier (1 SMS/day per server IP) or a
 * paid key for volume. Set it via {@code app.sms.textbelt.key} (env
 * {@code TEXTBELT_KEY}). No Twilio account required.
 */
public class TextBeltSmsSender implements SmsSender {

    private static final Logger log = LoggerFactory.getLogger(TextBeltSmsSender.class);
    private static final ObjectMapper MAPPER = new ObjectMapper();

    private final RestClient rest;
    private final String apiKey;

    public TextBeltSmsSender(String apiKey) {
        this.apiKey = apiKey;
        // Fail fast if textbelt.com is slow / unreachable, so an OTP request
        // never hangs past the client's timeout.
        SimpleClientHttpRequestFactory rf = new SimpleClientHttpRequestFactory();
        rf.setConnectTimeout(Duration.ofSeconds(3));
        rf.setReadTimeout(Duration.ofSeconds(5));
        this.rest = RestClient.builder().requestFactory(rf).build();
    }

    @Override
    public void send(String toPhone, String message) {
        MultiValueMap<String, String> form = new LinkedMultiValueMap<>();
        form.add("phone", toPhone);
        form.add("message", message);
        form.add("key", apiKey);

        String body;
        try {
            body = rest.post()
                    .uri("https://textbelt.com/text")
                    .contentType(MediaType.APPLICATION_FORM_URLENCODED)
                    .body(form)
                    .retrieve()
                    .body(String.class);
        } catch (RuntimeException e) {
            throw new IllegalStateException("TextBelt request failed: " + e.getMessage(), e);
        }

        JsonNode json;
        try {
            json = MAPPER.readTree(body == null ? "{}" : body);
        } catch (com.fasterxml.jackson.core.JsonProcessingException e) {
            throw new IllegalStateException("TextBelt returned an unreadable response: " + body, e);
        }

        if (!json.path("success").asBoolean(false)) {
            throw new IllegalStateException(
                    "TextBelt rejected the SMS: " + json.path("error").asText("unknown error"));
        }
        log.info("TextBelt SMS sent to {} (quotaRemaining={})",
                toPhone, json.path("quotaRemaining").asText("?"));
    }
}
