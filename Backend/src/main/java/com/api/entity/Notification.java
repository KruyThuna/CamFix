package com.api.entity;

import java.time.LocalDateTime;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "notification")
@Getter
@Setter
@NoArgsConstructor
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

    public Notification(Long notificationId, Users user, String title, String message, boolean isRead,
            LocalDateTime createdAt) {
        this.notificationId = notificationId;
        this.user = user;
        this.title = title;
        this.message = message;
        this.isRead = isRead;
        this.createdAt = createdAt;
    }
}
