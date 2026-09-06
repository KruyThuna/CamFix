package com.api.dto.Request;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data 
// Generates getAddress_Name(), getCity(), etc.
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserAddressRequest {
    private String address_Name;
    private String address_Line;
    private String city;
    private String province;
    private Long userId;
    private Boolean isDefault;
    private Double latitude;
    private Double longitude;
}