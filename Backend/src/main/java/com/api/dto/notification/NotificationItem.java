package com.api.dto.notification;

import com.api.entity.Notification;

/** One row of {@code GET /api/notifications/mine} - carries both languages so the
 *  app renders whichever the user picked. */
public class NotificationItem {

    private Long id;
    private String type;
    private Long jobId;
    private String title;
    private String message;
    private String titleKm;
    private String messageKm;
    private boolean read;
    private String createdAt;

    public static NotificationItem of(Notification n) {
        NotificationItem i = new NotificationItem();
        i.id = n.getNotificationId();
        i.type = n.getType();
        i.jobId = n.getJobId();
        i.title = n.getTitle();
        i.message = n.getMessage();
        i.titleKm = n.getTitleKm();
        i.messageKm = n.getMessageKm();
        i.read = n.isRead();
        i.createdAt = n.getCreatedAt() == null ? null : n.getCreatedAt().toString();
        return i;
    }

    public Long getId() {
        return id;
    }

    public String getType() {
        return type;
    }

    public Long getJobId() {
        return jobId;
    }

    public String getTitle() {
        return title;
    }

    public String getMessage() {
        return message;
    }

    public String getTitleKm() {
        return titleKm;
    }

    public String getMessageKm() {
        return messageKm;
    }

    public boolean isRead() {
        return read;
    }

    public String getCreatedAt() {
        return createdAt;
    }
}
