package com.api.exception;

/** A send was not accepted; never expose provider credentials or raw errors. */
public class SmsDeliveryException extends RuntimeException {
    public SmsDeliveryException(String message) {
        super(message);
    }
}
