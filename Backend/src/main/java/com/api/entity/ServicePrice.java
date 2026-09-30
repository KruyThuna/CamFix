package com.api.entity;

import java.time.LocalDateTime;

import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * The "starting from" catalog price shown to a customer before they book -
 * NOT the final repair cost (see {@link ServiceQuote}). One row per category,
 * kept flat (categoryId only, no JPA relation) to match {@link Job}'s style.
 */
@Entity
@Table(name = "service_price")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ServicePrice {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "category_id", nullable = false, unique = true)
    private Long categoryId;

    @Column(name = "starting_price", nullable = false)
    private Double startingPrice;

    @Column(length = 255)
    private String description;

    /** Self Drop diagnostic fee, paid at drop-off. Admin-set; null = not offered.
     *  Snapshotted onto the job and honoured as the quote's inspection fee. */
    @Column(name = "bench_fee")
    private Double benchFee;

    /** Standard home-visit travel fee. Admin-set; null = not configured. A Self
     *  Drop job never charges travel (enforced when the technician quotes). */
    @Column(name = "travel_fee")
    private Double travelFee;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Long getCategoryId() {
        return categoryId;
    }

    public void setCategoryId(Long categoryId) {
        this.categoryId = categoryId;
    }

    public Double getStartingPrice() {
        return startingPrice;
    }

    public void setStartingPrice(Double startingPrice) {
        this.startingPrice = startingPrice;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public Double getBenchFee() {
        return benchFee;
    }

    public void setBenchFee(Double benchFee) {
        this.benchFee = benchFee;
    }

    public Double getTravelFee() {
        return travelFee;
    }

    public void setTravelFee(Double travelFee) {
        this.travelFee = travelFee;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }
}
