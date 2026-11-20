package com.api.modules.auth.dto;

/** Body for {@code POST /api/auth/email/request-otp}. */
public class EmailOtpRequest {

    private String email;

    public EmailOtpRequest() {
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }
}
