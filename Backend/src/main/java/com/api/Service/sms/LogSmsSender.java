package com.api.Service.sms;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/** Fallback used when no SMS provider is configured: writes the message to the
 *  server log instead of sending it. */
public class LogSmsSender implements SmsSender {

    private static final Logger log = LoggerFactory.getLogger(LogSmsSender.class);

    @Override
    public void send(String toPhone, String message) {
        log.info("[SMS -> {}] {}", toPhone, message);
    }
}
