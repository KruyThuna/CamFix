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
 * One named, priced service a technician offers (e.g. "AC Refrigerant
 * Recharge - $45"), managed by the technician themselves. Kept flat like
 * {@link Job} - technician referenced by id only, no JPA relation. Named
 * "...Listing" (not just {@code TechnicianService}) to avoid colliding with
 * the pre-existing {@code com.api.Service.TechnicianService} class.
 */
@Entity
@Table(name = "technician_service")
public class TechnicianServiceListing {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "technician_id", nullable = false)
    private Long technicianId;

    @Column(nullable = false, length = 120)
    private String title;

    @Column(nullable = false)
    private Double price;

    /** Free text the technician writes themselves - one feature per line,
     *  shown as bullet points on the customer app's listing card. Optional. */
    @Column(length = 500)
    private String description;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    /** Set when a photo exists in {@link TechnicianServicePhoto}; null = none. */
    @Column(name = "photo_content_type", length = 100)
    private String photoContentType;

    /** Epoch millis of the last photo change - cache-busts the photo URL. */
    @Column(name = "photo_version")
    private Long photoVersion;

    public String getPhotoContentType() {
        return photoContentType;
    }

    public void setPhotoContentType(String photoContentType) {
        this.photoContentType = photoContentType;
    }

    public Long getPhotoVersion() {
        return photoVersion;
    }

    public void setPhotoVersion(Long photoVersion) {
        this.photoVersion = photoVersion;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Long getTechnicianId() {
        return technicianId;
    }

    public void setTechnicianId(Long technicianId) {
        this.technicianId = technicianId;
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

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}
