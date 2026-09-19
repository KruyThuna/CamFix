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
 * A technician's itemized repair quote for a {@link Job}, versioned so a
 * revised quote is a new row rather than an edit - see {@code Quote_Status}.
 * Kept flat (jobId/technicianId only) to match {@code Job}'s no-JPA-relations style.
 */
@Entity
@Table(name = "service_quote")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ServiceQuote {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "job_id", nullable = false)
    private Long jobId;

    @Column(name = "technician_id", nullable = false)
    private Long technicianId;

    @Column(nullable = false)
    private Integer version;

    @Column(name = "inspection_fee", nullable = false)
    @Builder.Default
    private Double inspectionFee = 0.0;

    @Column(name = "labor_cost", nullable = false)
    @Builder.Default
    private Double laborCost = 0.0;

    @Column(name = "parts_cost", nullable = false)
    @Builder.Default
    private Double partsCost = 0.0;

    @Column(name = "travel_fee", nullable = false)
    @Builder.Default
    private Double travelFee = 0.0;

    /** Always recomputed by the service layer from the four fees above - never
     *  accepted directly from a client request. */
    @Column(name = "total_amount", nullable = false)
    @Builder.Default
    private Double totalAmount = 0.0;

    @Column(length = 500)
    private String reason;

    /** PENDING | ACCEPTED | REJECTED | REVISED | EXPIRED */
    @Column(nullable = false, length = 20)
    private String status;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
