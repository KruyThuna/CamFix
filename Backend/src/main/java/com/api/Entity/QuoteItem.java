package com.api.Entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;

/**
 * One named line item on a technician's {@link ServiceQuote} (e.g. "AC Deep
 * Clean $15", "Fan blade replacement $7.99"). The customer approves or
 * declines each item when accepting the quote; only approved items count
 * toward the quote total and only those get done.
 */
@Entity
@Table(name = "quote_item", indexes = @Index(name = "idx_quote_item_quote", columnList = "quote_id"))
public class QuoteItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "quote_id", nullable = false)
    private Long quoteId;

    @Column(nullable = false, length = 120)
    private String title;

    @Column(nullable = false)
    private Double price;

    @Column(length = 300)
    private String note;

    /** The technician marked this as recommended (not strictly required). */
    @Column(nullable = false)
    private boolean recommended;

    /** Customer decision: null until the quote is accepted. */
    @Column
    private Boolean approved;

    public Long getId() {
        return id;
    }

    public Long getQuoteId() {
        return quoteId;
    }

    public void setQuoteId(Long quoteId) {
        this.quoteId = quoteId;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public Double getPrice() {
        return price;
    }

    public void setPrice(Double price) {
        this.price = price;
    }

    public String getNote() {
        return note;
    }

    public void setNote(String note) {
        this.note = note;
    }

    public boolean isRecommended() {
        return recommended;
    }

    public void setRecommended(boolean recommended) {
        this.recommended = recommended;
    }

    public Boolean getApproved() {
        return approved;
    }

    public void setApproved(Boolean approved) {
        this.approved = approved;
    }
}
