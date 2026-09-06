package com.api.dto.Auth;

/** Body for {@code POST /api/auth/phone/verify-otp}. */
public class PhoneVerifyRequest {

    private String phoneNumber;
    private String code;

    public PhoneVerifyRequest() {
    }

    public String getPhoneNumber() {
        return phoneNumber;
    }

    public void setPhoneNumber(String phoneNumber) {
        this.phoneNumber = phoneNumber;
    }

    public String getCode() {
        return code;
    }

    public void setCode(String code) {
        this.code = code;
    }
}
