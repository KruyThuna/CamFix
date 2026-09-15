package com.api.dto.Auth;

/** Body for {@code PUT /api/auth/me/password}. */
public class SetPasswordRequest {

    private String newPassword;

    public SetPasswordRequest() {
    }

    public String getNewPassword() {
        return newPassword;
    }

    public void setNewPassword(String newPassword) {
        this.newPassword = newPassword;
    }
}
