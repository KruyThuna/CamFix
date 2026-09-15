package com.api.dto.Technician;

import lombok.Getter;
import lombok.Setter;

/** Payload for {@code GET/PUT /api/technician/me} - matches the Flutter
 *  {@code TechnicianProfile.fromJson}. */
@Getter
@Setter
public class TechnicianProfileResponse {

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
    private String rejectionReason;
    /** Relative path (e.g. {@code /api/technician/7/photo}) or null if no photo is set. */
    private String photoUrl;
}
