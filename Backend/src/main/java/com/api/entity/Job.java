package com.api.entity;

import java.time.LocalDateTime;

import org.hibernate.annotations.CreationTimestamp;

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
 * A dispatchable service job managed from the admin console. Kept deliberately
 * flat - the customer and technician are referenced by id only (no JPA
 * relations) so this table can be added without touching the existing
 * {@code users}/{@code technician} mappings.
 */
@Entity
@Table(name = "job")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Job {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "customer_name", nullable = false)
    private String customerName;

    @Column(name = "customer_phone", nullable = false)
    private String customerPhone;

    /** {@code users.Userid} of the customer, when the job came from a known account. */
    @Column(name = "customer_user_id")
    private Long customerUserId;

    @Column(nullable = false)
    private String category;

    @Column(nullable = false, length = 2000)
    private String description;

    private String address;

    private Double lat;

    private Double lng;

    /** REQUESTED | ASSIGNED | ON_THE_WAY | ARRIVED | IN_PROGRESS | COMPLETED | CANCELLED */
    @Column(nullable = false, length = 20)
    private String status;

    /** IMMEDIATE | SCHEDULED - drives the cancellation-fee schedule shown to the customer. */
    @Column(name = "booking_type", length = 20)
    private String bookingType;

    /** Snapshot of {@code ServicePrice.startingPrice} for this job's category at
     *  creation time - NOT the final repair cost. Never re-read live from
     *  ServicePrice so an admin's later price change can't rewrite history. */
    @Column(name = "starting_price")
    private Double startingPrice;

    /** {@code technician.technician_id} once dispatched. */
    @Column(name = "technician_id")
    private Long technicianId;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "scheduled_at")
    private LocalDateTime scheduledAt;

    @Column(name = "assigned_at")
    private LocalDateTime assignedAt;

    @Column(name = "completed_at")
    private LocalDateTime completedAt;

    @Column(length = 2000)
    private String notes;
}
