package com.api.modules.payment.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import org.hibernate.annotations.CreationTimestamp;

/** Immutable, payment-keyed ledger credit. The ledger is the source of truth for bot balances. */
@Entity
@Table(name = "technician_wallet_entry", uniqueConstraints =
        @UniqueConstraint(name = "uk_wallet_entry_payment", columnNames = "payment_id"))
public class TechnicianWalletEntry {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(name = "technician_id", nullable = false)
    private Long technicianId;
    @Column(name = "payment_id", nullable = false)
    private Long paymentId;
    @Column(name = "job_id", nullable = false)
    private Long jobId;
    @Column(nullable = false)
    private Double amount;
    @Column(nullable = false, length = 3)
    private String currency = "USD";
    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
    public Long getId() { return id; }
    public Long getTechnicianId() { return technicianId; }
    public void setTechnicianId(Long v) { technicianId = v; }
    public Long getPaymentId() { return paymentId; }
    public void setPaymentId(Long v) { paymentId = v; }
    public Long getJobId() { return jobId; }
    public void setJobId(Long v) { jobId = v; }
    public Double getAmount() { return amount; }
    public void setAmount(Double v) { amount = v; }
    public String getCurrency() { return currency; }
    public LocalDateTime getCreatedAt() { return createdAt; }
}
