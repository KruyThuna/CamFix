package com.api.dto.Response;

import java.math.BigDecimal;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
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
}
