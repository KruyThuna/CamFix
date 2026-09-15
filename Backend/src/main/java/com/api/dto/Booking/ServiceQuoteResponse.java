package com.api.dto.Booking;

/** Payload for reading a {@code ServiceQuote} - one version of a technician's
 *  itemized repair quote for a booking. */
public class ServiceQuoteResponse {

    private Long id;
    private Long jobId;
    private Long technicianId;
    private Integer version;
    private Double inspectionFee;
    private Double laborCost;
    private Double partsCost;
    private Double travelFee;
    private Double totalAmount;
    private String reason;
    private String status;
    private String createdAt;
    private String updatedAt;

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

    public String getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(String createdAt) {
        this.createdAt = createdAt;
    }

    public String getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(String updatedAt) {
        this.updatedAt = updatedAt;
    }
}
