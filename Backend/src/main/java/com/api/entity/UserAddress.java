package com.api.entity;

import jakarta.persistence.*;
import lombok.Builder;
import lombok.Data;

@Entity
@Table(name = "user_addresses")
@Data
@Builder
public class UserAddress {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "AddressID")
    private Long id;

    private String address_Name;
    private String address_Line;
    private String city;
    private String province;
    private Long userId;
    @Column(name = "Is_Default")
    @Builder.Default
    private Boolean isDefault = false;
    private Double latitude;
    private Double longitude;

    public UserAddress() {
    }

    public UserAddress(Long id, String address_Name, String address_Line, String city,
            String province, Long userId, Boolean isDefault, Double latitude, Double longitude) {
        this.id = id;
        this.address_Name = address_Name;
        this.address_Line = address_Line;
        this.city = city;
        this.province = province;
        this.userId = userId;
        this.isDefault = isDefault;
        this.latitude = latitude;
        this.longitude = longitude;
    }
}   
