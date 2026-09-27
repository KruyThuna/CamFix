package com.api.dto.Booking;

/** Payload for {@code GET /api/service-prices} - the "starting from" catalog
 *  price shown to a customer before booking. */
public class ServicePriceResponse {

    private Long categoryId;
    private String categoryName;
    private Double startingPrice;
    private String description;
    private Double benchFee;
    private Double travelFee;

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

    public Long getCategoryId() {
        return categoryId;
    }

    public void setCategoryId(Long categoryId) {
        this.categoryId = categoryId;
    }

    public String getCategoryName() {
        return categoryName;
    }

    public void setCategoryName(String categoryName) {
        this.categoryName = categoryName;
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
}
