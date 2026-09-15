package com.api.dto.Booking;

/** Body for {@code POST /api/technician/me/jobs/{id}/quotes}. */
public class SubmitQuoteRequest {

    private Double inspectionFee;
    private Double laborCost;
    private Double partsCost;
    private Double travelFee;
    private String reason;

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

    public String getReason() {
        return reason;
    }

    public void setReason(String reason) {
        this.reason = reason;
    }
}
