package com.api.dto.technician;

import lombok.Getter;
import lombok.Setter;

/** One row of {@code GET /api/technician/me/jobs} - matches the Flutter
 *  {@code TechJob.fromJson}. Internal admin notes are deliberately omitted. */
@Getter
@Setter
public class TechJobResponse {

    private Long id;
    private String customerName;
    private String customerPhone;
    private String category;
    private String description;
    private String address;
    private Double lat;
    private Double lng;
    private String status;
    private String createdAt;
    private String scheduledAt;
    private String assignedAt;
    private String completedAt;
}
