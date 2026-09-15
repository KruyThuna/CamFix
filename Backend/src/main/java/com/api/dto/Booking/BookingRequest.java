package com.api.dto.Booking;

import lombok.Getter;
import lombok.Setter;

/** Body for {@code POST /api/bookings} - sent by the customer app's booking sheet. */
@Getter
@Setter
public class BookingRequest {

    private String category;
    /** Optional sub-service label from the app ("Repair", "Clean", ...). */
    private String service;
    private String note;
    private String address;
    private Double lat;
    private Double lng;
    /** Optional ISO-8601 date-time the customer picked. */
    private String scheduledAt;
    /** Optional - name of the provider the customer tapped (mock list, no id yet). */
    private String providerName;
    /** Optional - assign straight to this technician if they exist and are approved. */
    private Long technicianId;
    /** IMMEDIATE | SCHEDULED. Blank/unrecognised defaults to IMMEDIATE. */
    private String bookingType;
}
