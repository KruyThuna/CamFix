package com.api.modules.auth.dto;

import lombok.Data;

@Data
public class FirebaseLoginRequest {
    private String idToken;

    public FirebaseLoginRequest() {}

    public FirebaseLoginRequest(String idToken) {
        this.idToken = idToken;
    }

    public String getIdToken() {
        return idToken;
    }

    public void setIdToken(String idToken) {
        this.idToken = idToken;
    }
}
