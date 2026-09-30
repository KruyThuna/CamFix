package com.api.dto.request;

import lombok.Data;

@Data
public class NotificationRequest {

    private Long userId;
    private String title;
    private String message;

    public NotificationRequest() {
    }

    public NotificationRequest(Long userId, String title, String message) {
        this.userId = userId;
        this.title = title;
        this.message = message;
    }

    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }
}
