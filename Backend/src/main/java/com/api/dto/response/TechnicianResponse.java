package com.api.dto.response;

import java.math.BigDecimal;

import lombok.Data;


@Data
public class TechnicianResponse {
    private Long technicialId;

    private String fullname;
    private String email;
    private String phone;
    private String categoryName;
    private int experainceYear;
    private String description;
    private BigDecimal agverageRating;
    private boolean verified;
    private String availabilityStatus;

    public TechnicianResponse() {
    }

    public TechnicianResponse(Long technicialId, String fullname, String email, String phone,
            String categoryName, int experainceYear, String description,
            BigDecimal agverageRating, boolean verified, String availabilityStatus) {
        this.technicialId = technicialId;
        this.fullname = fullname;
        this.email = email;
        this.phone = phone;
        this.categoryName = categoryName;
        this.experainceYear = experainceYear;
        this.description = description;
        this.agverageRating = agverageRating;
        this.verified = verified;
        this.availabilityStatus = availabilityStatus;
    }
}
