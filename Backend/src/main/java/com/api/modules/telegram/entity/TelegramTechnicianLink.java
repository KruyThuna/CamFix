package com.api.modules.telegram.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import org.hibernate.annotations.CreationTimestamp;

@Entity
@Table(name = "telegram_technician_link", uniqueConstraints = {
        @UniqueConstraint(name = "uk_telegram_chat_id", columnNames = "chat_id"),
        @UniqueConstraint(name = "uk_telegram_technician_id", columnNames = "technician_id")
})
public class TelegramTechnicianLink {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(name = "technician_id", nullable = false)
    private Long technicianId;
    @Column(name = "chat_id", nullable = false, length = 32)
    private String chatId;
    @Column(name = "telegram_user_id", length = 32)
    private String telegramUserId;
    @CreationTimestamp
    @Column(name = "linked_at", nullable = false, updatable = false)
    private LocalDateTime linkedAt;
    public Long getId() { return id; }
    public Long getTechnicianId() { return technicianId; }
    public void setTechnicianId(Long v) { technicianId = v; }
    public String getChatId() { return chatId; }
    public void setChatId(String v) { chatId = v; }
    public String getTelegramUserId() { return telegramUserId; }
    public void setTelegramUserId(String v) { telegramUserId = v; }
    public LocalDateTime getLinkedAt() { return linkedAt; }
}
