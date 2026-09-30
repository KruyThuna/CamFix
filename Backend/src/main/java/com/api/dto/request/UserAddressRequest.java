package com.api.dto.request;

import lombok.Builder;
import lombok.Data;

@Data 
// Generates getAddress_Name(), getCity(), etc.
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

    public UserAddressRequest() {
    }

    public UserAddressRequest(String address_Name, String address_Line, String city,
            String province, Long userId, Boolean isDefault, Double latitude, Double longitude) {
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
