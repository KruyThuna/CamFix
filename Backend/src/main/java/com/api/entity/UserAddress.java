package com.api.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "user_addresses")
@Data
@NoArgsConstructor
@AllArgsConstructor
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
}   
