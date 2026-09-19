package com.api.entity;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "technician")
@Getter
@Setter
@NoArgsConstructor
public class Technician {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "technician_id")
    private Long technicianId;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private Users users;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id", nullable = false)
    private Category category;

    @Column(name = "business_name", nullable = false)
    private String businessName;

    @Column(name = "experience_year", nullable = false)
    private int experienceYear;

    @Column(length = 500)
    private String description;

    @Column(name = "average_rating", precision = 3, scale = 2)
    private BigDecimal averageRating;

    @Column(nullable = false)
    private boolean verified = false;

    @Column(name = "availability_status", length = 20)
    private String availabilityStatus;

    // --- Admin-console fields (all nullable; added for the /api/admin surface) ---

    /** PENDING | APPROVED | REJECTED. Null is treated as PENDING. */
    @Column(name = "approval_status", length = 20)
    private String approvalStatus;

    @Column(name = "approved_at")
    private LocalDateTime approvedAt;

    @Column(name = "rejection_reason", length = 500)
    private String rejectionReason;

    @Column(name = "service_area")
    private String serviceArea;

    @Column(name = "opening_hours")
    private String openingHours;

    @Column(name = "rating_count")
    private Integer ratingCount;

    /** Profile photo, uploaded from the technician app. Stored in the DB -
     *  there's no object storage / CDN in this project. */
    @Lob
    @Column(name = "photo", columnDefinition = "LONGBLOB")
    private byte[] photo;

    @Column(name = "photo_content_type", length = 100)
    private String photoContentType;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }
}
