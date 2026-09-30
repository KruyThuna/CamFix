package com.api.entity;

import java.time.LocalDateTime;

import org.hibernate.annotations.CreationTimestamp;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/**
 * A mock payment against an accepted {@link ServiceQuote} - no real card
 * processor is wired up in this project, so this just records that the
 * customer "paid" (see {@code BookingService#payQuote}). Kept flat
 * (jobId/quoteId only) to match {@code Job}/{@code ServiceQuote}'s
 * no-JPA-relations style. One row per quote - paying again for an
 * already-paid quote returns the existing row instead of creating a new one.
 */
@Entity
@Table(name = "payment")
public class Payment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "job_id", nullable = false)
    private Long jobId;

    @Column(name = "quote_id", nullable = false, unique = true)
    private Long quoteId;

    @Column(name = "base_amount", nullable = false)
    private Double baseAmount;

    @Column(name = "platform_fee", nullable = false)
    private Double platformFee;

    @Column(name = "tax_amount", nullable = false)
    private Double taxAmount;

    @Column(name = "total_amount", nullable = false)
    private Double totalAmount;

    /** APPLE_PAY | CARD | PAYPAL */
    @Column(name = "payment_method", nullable = false, length = 20)
    private String paymentMethod;

    /** Last 4 digits only when {@link #paymentMethod} is CARD - never a full
     *  card number, this app never collects or stores one. */
    @Column(name = "card_last4", length = 4)
    private String cardLast4;

    /** Customer-facing reference shown on the receipt, e.g. "SP-93217-KQ". */
    @Column(name = "service_ref", nullable = false, length = 20)
    private String serviceRef;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
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

    public Double getBaseAmount() {
        return baseAmount;
    }

    public void setBaseAmount(Double baseAmount) {
        this.baseAmount = baseAmount;
    }

    public Double getPlatformFee() {
        return platformFee;
    }

    public void setPlatformFee(Double platformFee) {
        this.platformFee = platformFee;
    }

    public Double getTaxAmount() {
        return taxAmount;
    }

    public void setTaxAmount(Double taxAmount) {
        this.taxAmount = taxAmount;
    }

    public Double getTotalAmount() {
        return totalAmount;
    }

    public void setTotalAmount(Double totalAmount) {
        this.totalAmount = totalAmount;
    }

    public String getPaymentMethod() {
        return paymentMethod;
    }

    public void setPaymentMethod(String paymentMethod) {
        this.paymentMethod = paymentMethod;
    }

    public String getCardLast4() {
        return cardLast4;
    }

    public void setCardLast4(String cardLast4) {
        this.cardLast4 = cardLast4;
    }

    public String getServiceRef() {
        return serviceRef;
    }

    public void setServiceRef(String serviceRef) {
        this.serviceRef = serviceRef;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
}
