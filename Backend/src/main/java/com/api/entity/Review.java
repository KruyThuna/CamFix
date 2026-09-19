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
import jakarta.persistence.UniqueConstraint;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * A customer's rating of a completed job. Kept deliberately flat like
 * {@link Job} and {@link ServiceQuote} - customer/technician/job are plain id
 * columns, no JPA relations. One review per job (enforced both here and in
 * {@code ReviewService}), so a job's unique id is the natural review key.
 */
@Entity
@Table(name = "review", uniqueConstraints = {
        @UniqueConstraint(name = "UQ_Review_Job", columnNames = { "job_id" })
})
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Review {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "job_id", nullable = false)
    private Long jobId;

    @Column(name = "customer_user_id", nullable = false)
    private Long customerUserId;

    @Column(name = "technician_id", nullable = false)
    private Long technicianId;

    /** 1-5. */
    @Column(nullable = false)
    private Integer rating;

    @Column(length = 1000)
    private String comment;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
