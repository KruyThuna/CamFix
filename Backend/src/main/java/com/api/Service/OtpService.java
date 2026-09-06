package com.api.Service;

import java.security.SecureRandom;
import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import com.api.Service.mail.EmailSender;
import com.api.Service.sms.SmsSender;

/**
 * In-memory one-time-password store shared by phone- and email-based login.
 *
 * <p>Kept in memory because the schema is externally managed
 * ({@code spring.jpa.hibernate.ddl-auto=none}) so a dedicated OTP table would
 * have to be created by hand. Fine for a single-instance dev setup; move to a
 * shared store (DB / Redis) before running more than one instance.
 */
@Service
public class OtpService {

    private static final Logger log = LoggerFactory.getLogger(OtpService.class);
    private static final SecureRandom RNG = new SecureRandom();

    private final long ttlSeconds;
    private final int maxAttempts;
    private final boolean exposeCode;
    private final SmsSender smsSender;
    private final EmailSender emailSender;

    private final Map<String, Entry> store = new ConcurrentHashMap<>();

    public OtpService(
            SmsSender smsSender,
            EmailSender emailSender,
            @Value("${app.otp.ttl-seconds:300}") long ttlSeconds,
            @Value("${app.otp.max-attempts:5}") int maxAttempts,
            @Value("${app.otp.expose-code:true}") boolean exposeCode) {
        this.smsSender = smsSender;
        this.emailSender = emailSender;
        this.ttlSeconds = ttlSeconds;
        this.maxAttempts = maxAttempts;
        this.exposeCode = exposeCode;
    }

    private static final class Entry {
        final String code;
        final long expiresAt;
        int attempts;

        Entry(String code, long expiresAt) {
            this.code = code;
            this.expiresAt = expiresAt;
        }
    }

    private long ttlMinutes() {
        return Math.max(1, ttlSeconds / 60);
    }

    private String message(String code) {
        return "Your CAM FIX verification code is " + code
                + ". It expires in " + ttlMinutes() + " minute"
                + (ttlMinutes() == 1 ? "" : "s") + ".";
    }

    private String store(String key) {
        String code = String.format("%06d", RNG.nextInt(1_000_000));
        store.put(key, new Entry(code, Instant.now().getEpochSecond() + ttlSeconds));
        return code;
    }

    /** Generate + store a code for {@code phone}, then send it by SMS. Returns
     *  the code only when {@code app.otp.expose-code} is true. */
    public String issuePhone(String phone) {
        String code = store(phone);
        deliver(() -> smsSender.send(toE164(phone), message(code)), "SMS", phone);
        return exposeCode ? code : null;
    }

    /** Generate + store a code for {@code email}, then send it by email. Returns
     *  the code only when {@code app.otp.expose-code} is true. */
    public String issueEmail(String email) {
        String code = store(email);
        deliver(() -> emailSender.send(email, "Your CAM FIX verification code", message(code)),
                "email", email);
        return exposeCode ? code : null;
    }

    /** Run a delivery attempt.
     *  <ul>
     *    <li>Provider says the recipient is invalid / unroutable → always fail
     *        (400), so the app tells the user to fix the number / address.</li>
     *    <li>Any other failure (quota, rate limit, network) → logged but not
     *        fatal while {@code expose-code=true}; propagated in production.</li>
     *  </ul>
     */
    private void deliver(Runnable send, String channel, String to) {
        try {
            send.run();
        } catch (RuntimeException e) {
            String msg = String.valueOf(e.getMessage()).toLowerCase();
            boolean badRecipient = msg.contains("invalid")
                    || msg.contains("not a mobile")
                    || msg.contains("could not be parsed")
                    || msg.contains("unroutable")
                    || msg.contains("no matching")
                    || msg.contains("is not a valid");
            if (badRecipient) {
                throw new IllegalArgumentException("SMS".equals(channel)
                        ? "That phone number can't receive SMS - check the number"
                        : "That email address is not deliverable");
            }
            if (exposeCode) {
                log.warn("{} delivery to {} failed ({}); code still returned in the response",
                        channel, to, e.getMessage());
            } else {
                throw e;
            }
        }
    }

    /** Best-effort E.164: keep a leading '+' and digits only. */
    private static String toE164(String phone) {
        String digits = phone.replaceAll("[^\\d]", "");
        return phone.trim().startsWith("+") ? "+" + digits : digits;
    }

    public boolean isExposeCode() {
        return exposeCode;
    }

    /** @return true when {@code code} matches the outstanding OTP for {@code key}
     *  (a phone number or an email address). */
    public boolean verify(String key, String code) {
        Entry e = store.get(key);
        if (e == null) {
            return false;
        }
        if (Instant.now().getEpochSecond() > e.expiresAt || e.attempts >= maxAttempts) {
            store.remove(key);
            return false;
        }
        e.attempts++;
        boolean ok = e.code.equals(code);
        if (ok) {
            store.remove(key);
        }
        return ok;
    }
}
