package com.api.modules.telegram.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "telegram_link_code")
public class TelegramLinkCode {
    @Id @Column(length = 64)
    private String code;
    @Column(name = "technician_id", nullable = false)
    private Long technicianId;
    @Column(name = "expires_at", nullable = false)
    private LocalDateTime expiresAt;
    public String getCode() { return code; }
    public void setCode(String v) { code = v; }
    public Long getTechnicianId() { return technicianId; }
    public void setTechnicianId(Long v) { technicianId = v; }
    public LocalDateTime getExpiresAt() { return expiresAt; }
    public void setExpiresAt(LocalDateTime v) { expiresAt = v; }
}
