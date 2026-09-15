package com.api.Entity;

import java.time.LocalDateTime;

import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/**
 * A technician's itemized repair quote for a {@link Job}, versioned so a
 * revised quote is a new row rather than an edit - see {@code Quote_Status}.
 * Kept flat (jobId/technicianId only) to match {@code Job}'s no-JPA-relations style.
 */
@Entity
@Table(name = "service_quote")
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
    private Double inspectionFee = 0.0;

    @Column(name = "labor_cost", nullable = false)
    private Double laborCost = 0.0;

    @Column(name = "parts_cost", nullable = false)
    private Double partsCost = 0.0;

    @Column(name = "travel_fee", nullable = false)
    private Double travelFee = 0.0;

    /** Always recomputed by the service layer from the four fees above - never
     *  accepted directly from a client request. */
    @Column(name = "total_amount", nullable = false)
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

    public Long getTechnicianId() {
        return technicianId;
    }

    public void setTechnicianId(Long technicianId) {
        this.technicianId = technicianId;
    }

    public Integer getVersion() {
        return version;
    }

    public void setVersion(Integer version) {
        this.version = version;
    }

    public Double getInspectionFee() {
        return inspectionFee;
    }

    public void setInspectionFee(Double inspectionFee) {
        this.inspectionFee = inspectionFee;
    }

    public Double getLaborCost() {
        return laborCost;
    }

    public void setLaborCost(Double laborCost) {
        this.laborCost = laborCost;
    }

    public Double getPartsCost() {
        return partsCost;
    }

    public void setPartsCost(Double partsCost) {
        this.partsCost = partsCost;
    }

    public Double getTravelFee() {
        return travelFee;
    }

    public void setTravelFee(Double travelFee) {
        this.travelFee = travelFee;
    }

    public Double getTotalAmount() {
        return totalAmount;
    }

    public void setTotalAmount(Double totalAmount) {
        this.totalAmount = totalAmount;
    }

    public String getReason() {
        return reason;
    }

    public void setReason(String reason) {
        this.reason = reason;
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

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }
}
