package com.api.dto.Response;

import com.api.Entity.TechnicianLiveLocation;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LocationResponse {

    private Long id;
    private Long technicianId;
    private Double latitude;
    private Double longitude;
    private Double accuracy;
    private LocalDateTime lastUpdate;

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