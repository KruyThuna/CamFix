package com.api.entity;

import java.time.LocalDateTime;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Builder;
import lombok.Data;

@Entity
@Table(name = "technician_addresses")
@Data
@Builder
public class TechnicianAddresses {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "AddressID")
    private Long addressId;

    // Use @Column instead of @JoinColumn when mapping a raw Long foreign key
    @Column(name = "technician_id")
    private Long technicianId;

    @Column(name = "business_name")
    private String businessName;

    @Column(name = "address_line")
    private String addressLine;

    @Column(name = "city")
    private String city;

    @Column(name = "province")
    private String province;

    @Column(name = "latitude")
    private Double latitude;

    @Column(name = "longitude")
    private Double longitude;

    @Column(name = "is_default")
    private Boolean isDefault;

    @CreationTimestamp
    @Column(name = "create_at", updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "update_at")
    private LocalDateTime updatedAt;

    public TechnicianAddresses() {
    }

    public TechnicianAddresses(Long addressId, Long technicianId, String businessName,
            String addressLine, String city, String province, Double latitude, Double longitude,
            Boolean isDefault, LocalDateTime createdAt, LocalDateTime updatedAt) {
        this.addressId = addressId;
        this.technicianId = technicianId;
        this.businessName = businessName;
        this.addressLine = addressLine;
        this.city = city;
        this.province = province;
        this.latitude = latitude;
        this.longitude = longitude;
        this.isDefault = isDefault;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }
}
