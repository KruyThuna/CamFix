package com.api.dto.Auth;

public class LoginRequest {
    private String email;

    public String getEmail() {
        return email;
    }

    public String getPassword() {
        return password;
    }

    private String password;

    public void setEmail(String email) {
        this.email = email;
    }

    public void setPassword(String password) {
        this.password = password;
    }

}
