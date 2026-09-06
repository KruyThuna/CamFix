package com.api.Service.sms;

import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.Base64;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestClient;

/**
 * Sends SMS through Twilio's REST API directly (no Twilio SDK dependency):
 * {@code POST https://api.twilio.com/2010-04-01/Accounts/{sid}/Messages.json}
 * with HTTP Basic auth and a form-encoded body.
 */
public class TwilioSmsSender implements SmsSender {

    private static final Logger log = LoggerFactory.getLogger(TwilioSmsSender.class);

    private final RestClient rest;
    private final String fromNumber;

    public TwilioSmsSender(String accountSid, String authToken, String fromNumber) {
        this.fromNumber = fromNumber;
        String basic = Base64.getEncoder().encodeToString(
                (accountSid + ":" + authToken).getBytes(StandardCharsets.UTF_8));
        SimpleClientHttpRequestFactory rf = new SimpleClientHttpRequestFactory();
        rf.setConnectTimeout(Duration.ofSeconds(3));
        rf.setReadTimeout(Duration.ofSeconds(8));
        this.rest = RestClient.builder()
                .requestFactory(rf)
                .baseUrl("https://api.twilio.com/2010-04-01/Accounts/" + accountSid)
                .defaultHeader(HttpHeaders.AUTHORIZATION, "Basic " + basic)
                .build();
    }

    @Override
    public void send(String toPhone, String message) {
        MultiValueMap<String, String> form = new LinkedMultiValueMap<>();
        form.add("To", toPhone);
        form.add("From", fromNumber);
        form.add("Body", message);

        try {
            rest.post()
                    .uri("/Messages.json")
                    .contentType(MediaType.APPLICATION_FORM_URLENCODED)
                    .body(form)
                    .retrieve()
                    .toBodilessEntity();
            log.info("Twilio SMS queued for {}", toPhone);
        } catch (RuntimeException e) {
            throw new IllegalStateException("Twilio SMS send failed: " + e.getMessage(), e);
        }
    }
}
