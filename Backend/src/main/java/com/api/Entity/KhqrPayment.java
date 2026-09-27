package com.api.Entity;

import java.time.LocalDateTime;

import org.hibernate.annotations.CreationTimestamp;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/**
 * One KHQR code generated for a quote. Stays PENDING until Bakong confirms a
 * matching transfer by MD5 (then PAID and a {@link Payment} row is written),
 * or EXPIRED once its expiry passes.
 */
@Entity
@Table(name = "khqr_payment")
public class KhqrPayment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "job_id", nullable = false)
    private Long jobId;

    @Column(name = "quote_id", nullable = false)
    private Long quoteId;

    @Column(nullable = false, unique = true, length = 32)
    private String md5;

    @Column(name = "qr_string", nullable = false, length = 600)
    private String qrString;

    @Column(nullable = false)
    private Double amount;

    /** PENDING | PAID | EXPIRED */
    @Column(nullable = false, length = 10)
    private String status;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "expires_at", nullable = false)
    private LocalDateTime expiresAt;

    /** Bakong's transaction hash, once paid. */
    @Column(name = "bakong_hash", length = 100)
    private String bakongHash;

    public Long getId() {
        return id;
    }

    public Long getJobId() {
        return jobId;
    }

    public void setJobId(Long jobId) {
        this.jobId = jobId;
    }

    public Long getQuoteId() {
        return quoteId;
    }

    public void setQuoteId(Long quoteId) {
        this.quoteId = quoteId;
    }

    public String getMd5() {
        return md5;
    }

    public void setMd5(String md5) {
        this.md5 = md5;
    }

    public String getQrString() {
        return qrString;
    }

    public void setQrString(String qrString) {
        this.qrString = qrString;
    }

    public Double getAmount() {
        return amount;
    }

    public void setAmount(Double amount) {
        this.amount = amount;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public LocalDateTime getExpiresAt() {
        return expiresAt;
    }

    public void setExpiresAt(LocalDateTime expiresAt) {
        this.expiresAt = expiresAt;
    }

    public String getBakongHash() {
        return bakongHash;
    }

    public void setBakongHash(String bakongHash) {
        this.bakongHash = bakongHash;
    }
}
