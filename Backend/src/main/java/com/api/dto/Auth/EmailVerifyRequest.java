package com.api.dto.Auth;

/** Body for {@code POST /api/auth/email/verify-otp}. */
public class EmailVerifyRequest {

    private String email;
    private String code;

    public EmailVerifyRequest() {
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getCode() {
        return code;
    }

    public void setCode(String code) {
        this.code = code;
    }
}
