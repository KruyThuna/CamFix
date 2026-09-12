package com.api.Service.sms;

/** Sends a short text message to a phone number. */
public interface SmsSender {

    /**
     * @param toPhone recipient in E.164-ish form (e.g. {@code +85597...})
     * @param message message body
     * @throws RuntimeException if the provider rejects the send
     */
    void send(String toPhone, String message);
}
