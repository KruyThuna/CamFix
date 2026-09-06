package com.api.Service.mail;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/** Fallback used when no SMTP server is configured: writes the email to the
 *  server log instead of sending it. */
public class LogEmailSender implements EmailSender {

    private static final Logger log = LoggerFactory.getLogger(LogEmailSender.class);

    @Override
    public void send(String to, String subject, String body) {
        log.info("[EMAIL -> {}] {} | {}", to, subject, body);
    }
}
