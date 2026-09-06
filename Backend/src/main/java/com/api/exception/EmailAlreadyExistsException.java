package com.api.exception;

/** Thrown when a registration is attempted with an email that is already taken. */
public class EmailAlreadyExistsException extends RuntimeException {

    public EmailAlreadyExistsException(String message) {
        super(message);
    }
}
