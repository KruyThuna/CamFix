package com.api.exception;

/** Thrown when an authenticated user lacks the role required for an endpoint. */
public class ForbiddenException extends RuntimeException {

    public ForbiddenException(String message) {
        super(message);
    }
}
