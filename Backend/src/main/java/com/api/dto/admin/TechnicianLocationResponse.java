package com.api.dto.admin;

import lombok.Getter;
import lombok.Setter;

/** One marker on the admin live map ({@code GET /api/admin/technicians/locations}). */
@Getter
@Setter
public class TechnicianLocationResponse {

    private Long id;
    private String name;
    private String category;
    private double lat;
    private double lng;
    private boolean available;
    private String lastLocationAt;
}
