package com.api.dto.request;

import jakarta.validation.constraints.NotNull;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class LocationRequest {

    @NotNull(message = "Technician ID is required")
    private Long technicianId;

    @NotNull(message = "Latitude is required")
    private Double latitude;

    @NotNull(message = "Longitude is required")
    private Double longitude;

    private Double accuracy;

    public LocationRequest() {
    }

    public LocationRequest(Long technicianId, Double latitude, Double longitude, Double accuracy) {
        this.technicianId = technicianId;
        this.latitude = latitude;
        this.longitude = longitude;
        this.accuracy = accuracy;
    }
}
