package com.api.dto.admin;

/**
 * Returned once, right after an admin resets a user's password. The plaintext
 * temporary password is only ever present in this response - it is not
 * retrievable afterwards, so the admin must relay it to the user out of band.
 */
public class AdminPasswordResetResponse {

    private Long userId;
    private String email;
    private String temporaryPassword;

    public AdminPasswordResetResponse() {
    }

    public AdminPasswordResetResponse(Long userId, String email, String temporaryPassword) {
        this.userId = userId;
        this.email = email;
        this.temporaryPassword = temporaryPassword;
    }

    public Long getUserId() {
        return userId;
    }

    public String getEmail() {
        return email;
    }

    public String getTemporaryPassword() {
        return temporaryPassword;
    }
}
