package com.api.dto.Auth;

/** Body for {@code POST /api/auth/phone/request-otp}. */
public class PhoneOtpRequest {

    private String phoneNumber;

    public PhoneOtpRequest() {
    }

    public String getPhoneNumber() {
        return phoneNumber;
    }

    public void setPhoneNumber(String phoneNumber) {
        this.phoneNumber = phoneNumber;
    }
}
