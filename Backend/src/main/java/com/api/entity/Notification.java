package com.api.entity;

import java.time.LocalDateTime;

import jakarta.persistence.*;

@Entity
@Table(name = "notification")
public class Notification {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "notification_id")
    private Long notificationId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private Users user;

    @Column(nullable = false, length = 150)
    private String title;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String message;

    /** Khmer copy of {@link #title}. Null falls back to {@link #title} in the app. */
    @Column(name = "title_km", length = 150)
    private String titleKm;

    /** Khmer copy of {@link #message}. Null falls back to {@link #message}. */
    @Column(name = "message_km", columnDefinition = "TEXT")
    private String messageKm;

    /** BOOKING_REQUESTED | JOB_ASSIGNED | JOB_IN_PROGRESS | JOB_COMPLETED | JOB_CANCELLED | JOB_DECLINED */
    @Column(length = 40)
    private String type;

    /** {@code job.id} this notification is about, when applicable. */
    @Column(name = "job_id")
    private Long jobId;

    @Column(name = "is_read")
    private boolean isRead = false;

    @Column(name = "created_at")
    private LocalDateTime createdAt = LocalDateTime.now();

    public Notification() {
    }

    public Notification(Long notificationId, Users user, String title, String message, boolean isRead,
            LocalDateTime createdAt) {
        this.notificationId = notificationId;
        this.user = user;
        this.title = title;
        this.message = message;
        this.isRead = isRead;
        this.createdAt = createdAt;
    }

    public Long getNotificationId() {
        return notificationId;
    }

    public Users getUser() {
        return user;
    }

    public String getTitle() {
        return title;
    }

    public String getMessage() {
        return message;
    }

    public boolean isRead() {
        return isRead;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setNotificationId(Long notificationId) {
        this.notificationId = notificationId;
    }

    public void setUser(Users user) {
        this.user = user;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public void setRead(boolean isRead) {
        this.isRead = isRead;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public String getTitleKm() {
        return titleKm;
    }

    public void setTitleKm(String titleKm) {
        this.titleKm = titleKm;
    }

    public String getMessageKm() {
        return messageKm;
    }

    public void setMessageKm(String messageKm) {
        this.messageKm = messageKm;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public Long getJobId() {
        return jobId;
    }

    public void setJobId(Long jobId) {
        this.jobId = jobId;
    }

}