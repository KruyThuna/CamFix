package com.api.dto.Admin;

import lombok.Getter;
import lombok.Setter;

/** Body for creating ({@code POST}) or updating ({@code PUT}) a technician. */
@Getter
@Setter
public class AdminTechnicianRequest {

    private String firstName;
    private String lastName;
    private String email;
    private String phoneNumber;
    private String category;
    private String serviceArea;
    private String about;
    private String openingHours;
    private Double rating;
    private Boolean available;
}
