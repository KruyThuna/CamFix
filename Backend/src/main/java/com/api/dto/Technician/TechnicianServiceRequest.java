package com.api.dto.Technician;

import lombok.Getter;
import lombok.Setter;

/** Body for creating/updating one of a technician's own named service listings. */
@Getter
@Setter
public class TechnicianServiceRequest {

    private String title;
    private Double price;
    private String description;
}
