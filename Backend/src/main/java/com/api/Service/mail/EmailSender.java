package com.api.Service.mail;

/** Sends a plain-text email. */
public interface EmailSender {

    /**
     * @param to      recipient address
     * @param subject subject line
     * @param body    plain-text body
     * @throws RuntimeException if the mail server rejects the send
     */
    void send(String to, String subject, String body);
}
