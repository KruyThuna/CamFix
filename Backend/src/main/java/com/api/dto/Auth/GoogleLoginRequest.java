package com.api.dto.Auth;

/** Body for {@code POST /api/auth/google}: the Google ID token obtained by the
 *  client (Flutter {@code google_sign_in}). */
public class GoogleLoginRequest {

    private String idToken;

    public GoogleLoginRequest() {
    }

    public GoogleLoginRequest(String idToken) {
        this.idToken = idToken;
    }

    public String getIdToken() {
        return idToken;
    }

    public void setIdToken(String idToken) {
        this.idToken = idToken;
    }
}
