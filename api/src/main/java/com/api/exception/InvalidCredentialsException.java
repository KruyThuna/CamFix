package com.api.exception;

/** Thrown when a login attempt fails email lookup or password verification. */
public class InvalidCredentialsException extends RuntimeException {

    public InvalidCredentialsException(String message) {
        super(message);
    }
}
