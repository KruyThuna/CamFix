package com.api.dto.booking;

import com.api.entity.Job;

/** Customer-facing view of a booking (a {@code job} row). */
public class BookingResponse {

    private Long id;
    private String category;
    private String description;
    private String status;
    private String bookingType;
    /** Snapshot "starting from" price shown when the booking was made - NOT
     *  the final repair cost. See {@code ServiceQuote} for the real total. */
    private Double startingPrice;
    private String address;
    private Double lat;
    private Double lng;
    private String scheduledAt;
    private String createdAt;
    private String assignedAt;
    private String completedAt;
    private Long technicianId;
    private String technicianName;
    private String technicianPhone;
    /** The assigned technician's last reported GPS fix, when one exists. */
    private Double technicianLat;
    private Double technicianLng;
    private String technicianLocationAt;

    public static BookingResponse of(Job job, String technicianName, String technicianPhone,
            Double technicianLat, Double technicianLng, String technicianLocationAt) {
        BookingResponse r = new BookingResponse();
        r.id = job.getId();
        r.category = job.getCategory();
        r.description = job.getDescription();
        r.status = job.getStatus();
        r.bookingType = job.getBookingType();
        r.startingPrice = job.getStartingPrice();
        r.address = job.getAddress();
        r.lat = job.getLat();
        r.lng = job.getLng();
        r.scheduledAt = job.getScheduledAt() == null ? null : job.getScheduledAt().toString();
        r.createdAt = job.getCreatedAt() == null ? null : job.getCreatedAt().toString();
        r.assignedAt = job.getAssignedAt() == null ? null : job.getAssignedAt().toString();
        r.completedAt = job.getCompletedAt() == null ? null : job.getCompletedAt().toString();
        r.technicianId = job.getTechnicianId();
        r.technicianName = technicianName;
        r.technicianPhone = technicianPhone;
        r.technicianLat = technicianLat;
        r.technicianLng = technicianLng;
        r.technicianLocationAt = technicianLocationAt;
        return r;
    }

    public Long getId() {
        return id;
    }

    public String getCategory() {
        return category;
    }

    public String getDescription() {
        return description;
    }

    public String getStatus() {
        return status;
    }

    public String getBookingType() {
        return bookingType;
    }

    public Double getStartingPrice() {
        return startingPrice;
    }

    public String getAddress() {
        return address;
    }

    public Double getLat() {
        return lat;
    }

    public Double getLng() {
        return lng;
    }

    public String getScheduledAt() {
        return scheduledAt;
    }

    public String getCreatedAt() {
        return createdAt;
    }

    public String getAssignedAt() {
        return assignedAt;
    }

    public String getCompletedAt() {
        return completedAt;
    }

    public Long getTechnicianId() {
        return technicianId;
    }

    public String getTechnicianName() {
        return technicianName;
    }

    public String getTechnicianPhone() {
        return technicianPhone;
    }

    public Double getTechnicianLat() {
        return technicianLat;
    }

    public Double getTechnicianLng() {
        return technicianLng;
    }

    public String getTechnicianLocationAt() {
        return technicianLocationAt;
    }
}
