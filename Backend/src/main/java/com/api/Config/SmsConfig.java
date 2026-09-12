package com.api.Config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import com.api.Service.sms.LogSmsSender;
import com.api.Service.sms.SmsSender;
import com.api.Service.sms.TextBeltSmsSender;
import com.api.Service.sms.TwilioSmsSender;

/**
 * Picks the {@link SmsSender} at startup, in order:
 * <ol>
 *   <li>Twilio - when {@code app.sms.twilio.account-sid / auth-token /
 *       from-number} are all set.</li>
 *   <li>TextBelt - when {@code app.sms.textbelt.key} is set (no signup;
 *       use {@code textbelt} for the free 1/day tier).</li>
 *   <li>Log-only - dev fallback, writes the code to the console.</li>
 * </ol>
 */
@Configuration
public class SmsConfig {

    private static final Logger log = LoggerFactory.getLogger(SmsConfig.class);

    @Bean
    public SmsSender smsSender(
            @Value("${app.sms.twilio.account-sid:}") String sid,
            @Value("${app.sms.twilio.auth-token:}") String token,
            @Value("${app.sms.twilio.from-number:}") String from,
            @Value("${app.sms.textbelt.key:}") String textbeltKey) {

        if (!sid.isBlank() && !token.isBlank() && !from.isBlank()) {
            log.info("SMS: using Twilio (from {})", from);
            return new TwilioSmsSender(sid.trim(), token.trim(), from.trim());
        }
        if (!textbeltKey.isBlank()) {
            log.info("SMS: using TextBelt");
            return new TextBeltSmsSender(textbeltKey.trim());
        }
        log.warn("SMS: no provider configured - OTP messages will only be logged. "
                + "Set app.sms.twilio.* (env TWILIO_*) or app.sms.textbelt.key (env TEXTBELT_KEY).");
        return new LogSmsSender();
    }
}
