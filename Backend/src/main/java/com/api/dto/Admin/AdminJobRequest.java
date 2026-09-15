package com.api.dto.Admin;

import lombok.Getter;
import lombok.Setter;

/** Body for creating ({@code POST}) or updating ({@code PUT}) a job. */
@Getter
@Setter
public class AdminJobRequest {

    private String customerName;
    private String customerPhone;
    private Long customerUserId;
    private String category;
    private String description;
    private String address;
    private Double lat;
    private Double lng;
    /** ISO-8601 instant from the console's datetime picker, e.g. {@code 2026-09-10T12:00:00.000Z}. */
    private String scheduledAt;
    private String notes;
}
