package com.api.service;

import java.math.BigDecimal;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.NoSuchElementException;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import com.api.entity.KhqrPayment;
import com.api.repository.KhqrPaymentRepository;
import com.api.dto.booking.PaymentResponse;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

/**
 * Real Bakong KHQR payments. The merchant's Bakong account id and API token
 * come from the environment (never the app):
 *
 * <pre>
 * BAKONG_ACCOUNT_ID     e.g. camfix@aclb
 * BAKONG_API_TOKEN      token from the Bakong Open API portal
 * BAKONG_MERCHANT_NAME  shown in the payer's banking app (default "CAMFIX")
 * BAKONG_MERCHANT_CITY  default "Phnom Penh"
 * BAKONG_API_BASE       default https://api-bakong.nbc.gov.kh
 * </pre>
 *
 * Without an account id + token the feature reports itself disabled and the
 * app simply doesn't offer KHQR.
 */
@Service
public class KhqrService {

    private static final Logger log = LoggerFactory.getLogger(KhqrService.class);
    private static final ObjectMapper MAPPER = new ObjectMapper();
    private static final ZoneId ZONE = ZoneId.systemDefault();

    public record KhqrConfig(boolean enabled, String merchantName) {
    }

    public record KhqrResponse(String qrString, String md5, double amount, String currency,
            String merchantName, String expiresAt) {
    }

    public record KhqrStatusResponse(String status, PaymentResponse payment) {
    }

    /** Internal result of a status check. */
    public record Check(String status, boolean paid, Long quoteId) {
    }

    private final KhqrPaymentRepository repository;
    private final String accountId;
    private final String apiToken;
    private final String merchantName;
    private final String merchantCity;
    private final String apiBase;
    private final long expirySeconds;
    private final HttpClient http = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(8)).build();

    public KhqrService(KhqrPaymentRepository repository,
            @Value("${app.khqr.account-id:}") String accountId,
            @Value("${app.khqr.api-token:}") String apiToken,
            @Value("${app.khqr.merchant-name:CAMFIX}") String merchantName,
            @Value("${app.khqr.merchant-city:Phnom Penh}") String merchantCity,
            @Value("${app.khqr.api-base:https://api-bakong.nbc.gov.kh}") String apiBase,
            @Value("${app.khqr.expiry-seconds:300}") long expirySeconds) {
        this.repository = repository;
        this.accountId = accountId == null ? "" : accountId.trim();
        this.apiToken = apiToken == null ? "" : apiToken.trim();
        this.merchantName = merchantName;
        this.merchantCity = merchantCity;
        this.apiBase = apiBase.endsWith("/") ? apiBase.substring(0, apiBase.length() - 1) : apiBase;
        this.expirySeconds = expirySeconds;
    }

    public boolean enabled() {
        return !accountId.isEmpty() && !apiToken.isEmpty();
    }

    public KhqrConfig config() {
        return new KhqrConfig(enabled(), merchantName);
    }

    KhqrResponse create(Long jobId, Long quoteId, double amountUsd) {
        if (!enabled()) {
            throw new IllegalArgumentException("KHQR payments are not configured on this server");
        }
        long now = System.currentTimeMillis();
        long expires = now + expirySeconds * 1000;
        String qr = KhqrCodec.build(accountId, merchantName, merchantCity,
                BigDecimal.valueOf(amountUsd), "CF" + jobId + "-" + quoteId, now, expires);
        String md5 = KhqrCodec.md5(qr);

        KhqrPayment row = new KhqrPayment();
        row.setJobId(jobId);
        row.setQuoteId(quoteId);
        row.setMd5(md5);
        row.setQrString(qr);
        row.setAmount(amountUsd);
        row.setStatus("PENDING");
        LocalDateTime expiresAt = LocalDateTime.ofInstant(java.time.Instant.ofEpochMilli(expires), ZONE);
        row.setExpiresAt(expiresAt);
        repository.save(row);
        return new KhqrResponse(qr, md5, amountUsd, "USD", merchantName, expiresAt.toString());
    }

    /** PENDING -> asks Bakong; PAID when a matching USD transfer is found. */
    Check check(Long jobId, String md5) {
        KhqrPayment row = repository.findByMd5AndJobId(md5, jobId)
                .orElseThrow(() -> new NoSuchElementException("KHQR not found"));
        if ("PAID".equals(row.getStatus())) {
            return new Check("PAID", true, row.getQuoteId());
        }
        JsonNode tx = lookup(md5);
        if (tx != null && amountMatches(tx, row.getAmount())) {
            row.setStatus("PAID");
            row.setBakongHash(tx.path("hash").asText(null));
            repository.save(row);
            return new Check("PAID", true, row.getQuoteId());
        }
        if (LocalDateTime.now(ZONE).isAfter(row.getExpiresAt())) {
            row.setStatus("EXPIRED");
            repository.save(row);
            return new Check("EXPIRED", false, row.getQuoteId());
        }
        return new Check("PENDING", false, row.getQuoteId());
    }

    private static boolean amountMatches(JsonNode tx, double expected) {
        String currency = tx.path("currency").asText("");
        double amount = tx.path("amount").asDouble(-1);
        return "USD".equalsIgnoreCase(currency) && Math.abs(amount - expected) < 0.005;
    }

    /** Bakong: transaction data for this MD5, or null when not (yet) paid. */
    private JsonNode lookup(String md5) {
        try {
            HttpRequest req = HttpRequest.newBuilder(URI.create(apiBase + "/v1/check_transaction_by_md5"))
                    .timeout(Duration.ofSeconds(10))
                    .header("Authorization", "Bearer " + apiToken)
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(
                            MAPPER.writeValueAsString(java.util.Map.of("md5", md5)),
                            StandardCharsets.UTF_8))
                    .build();
            HttpResponse<String> res = http.send(req, HttpResponse.BodyHandlers.ofString());
            if (res.statusCode() == 401 || res.statusCode() == 403) {
                log.warn("Bakong rejected the API token (HTTP {}) - renew BAKONG_API_TOKEN", res.statusCode());
                return null;
            }
            JsonNode body = MAPPER.readTree(res.body());
            // responseCode 0 = found; 1 = not found / error.
            if (body.path("responseCode").asInt(1) == 0 && body.hasNonNull("data")) {
                return body.get("data");
            }
            return null;
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            return null;
        } catch (Exception e) {
            log.warn("Bakong check_transaction_by_md5 failed: {}", e.getMessage());
            return null;
        }
    }
}
