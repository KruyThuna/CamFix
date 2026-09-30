package com.api.entity;

import java.time.LocalDateTime;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "technician_live_locations", indexes = {
        @Index(name = "idx_tech_location_last_update", columnList = "last_update")
})
@Getter
@Setter
@Builder
public class TechnicianLiveLocation {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "technician_id", nullable = false, unique = true)
    private Long technicianId;

    @Column(name = "latitude", nullable = false)
    private Double latitude;

    @Column(name = "longitude", nullable = false)
    private Double longitude;

    @Column(name = "accuracy")
    private Double accuracy;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "last_update")
    private LocalDateTime lastUpdate;

    public TechnicianLiveLocation() {
    }

    public TechnicianLiveLocation(Long id, Long technicianId, Double latitude, Double longitude,
            Double accuracy, LocalDateTime createdAt, LocalDateTime lastUpdate) {
        this.id = id;
        this.technicianId = technicianId;
        this.latitude = latitude;
        this.longitude = longitude;
        this.accuracy = accuracy;
        this.createdAt = createdAt;
        this.lastUpdate = lastUpdate;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o)
            return true;
        if (!(o instanceof TechnicianLiveLocation that))
            return false;
        return id != null && id.equals(that.getId());
    }

    @Override
    public int hashCode() {
        return getClass().hashCode();
    }
}
