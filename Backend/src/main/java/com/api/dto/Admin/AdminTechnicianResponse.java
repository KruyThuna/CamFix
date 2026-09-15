package com.api.dto.Admin;

import lombok.Getter;
import lombok.Setter;

/** Console-facing view of a technician (joins {@code technician} + {@code users} + last location). */
@Getter
@Setter
public class AdminTechnicianResponse {

    private Long id;
    private String firstName;
    private String lastName;
    private String email;
    private String phoneNumber;
    private String category;
    private String serviceArea;
    private String about;
    private String openingHours;
    private double rating;
    private int ratingCount;
    private String approvalStatus;
    private String accountStatus;
    private boolean available;
    private Double lastLat;
    private Double lastLng;
    private String lastLocationAt;
    private String createdAt;
    private String approvedAt;
    private String rejectionReason;
}
