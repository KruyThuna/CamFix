package com.api.Config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.mail.javamail.JavaMailSender;

import com.api.Service.mail.EmailSender;
import com.api.Service.mail.LogEmailSender;
import com.api.Service.mail.SmtpEmailSender;

/**
 * Picks the {@link EmailSender} at startup: SMTP when {@code spring.mail.host}
 * is set (Spring Boot then auto-configures a {@link JavaMailSender}), otherwise
 * a log-only sender (dev).
 */
@Configuration
public class MailConfig {

    private static final Logger log = LoggerFactory.getLogger(MailConfig.class);

    @Bean
    public EmailSender emailSender(
            ObjectProvider<JavaMailSender> mailSender,
            @Value("${spring.mail.host:}") String host,
            @Value("${app.mail.from:${spring.mail.username:no-reply@camfix.local}}") String from) {

        JavaMailSender sender = mailSender.getIfAvailable();
        if (!host.isBlank() && sender != null) {
            log.info("Mail: using SMTP {} (from {})", host, from);
            return new SmtpEmailSender(sender, from);
        }
        log.warn("Mail: no SMTP configured - OTP emails will only be logged. "
                + "Set spring.mail.host / spring.mail.username / spring.mail.password "
                + "(env MAIL_USERNAME / MAIL_PASSWORD for Gmail).");
        return new LogEmailSender();
    }
}
