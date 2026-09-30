package com.api.dto.response;

import com.api.entity.TechnicianLiveLocation;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class LocationResponse {

    private Long id;
    private Long technicianId;
    private Double latitude;
    private Double longitude;
    private Double accuracy;
    private LocalDateTime lastUpdate;

    public LocationResponse() {
    }

    public LocationResponse(Long id, Long technicianId, Double latitude, Double longitude,
            Double accuracy, LocalDateTime lastUpdate) {
        this.id = id;
        this.technicianId = technicianId;
        this.latitude = latitude;
        this.longitude = longitude;
        this.accuracy = accuracy;
        this.lastUpdate = lastUpdate;
    }

    public static LocationResponse fromEntity(TechnicianLiveLocation entity) {
        return LocationResponse.builder()
                .id(entity.getId())
                .technicianId(entity.getTechnicianId())
                .latitude(entity.getLatitude())
                .longitude(entity.getLongitude())
                .accuracy(entity.getAccuracy())
                .lastUpdate(entity.getLastUpdate())
                .build();
    }
}
