package com.api.dto.Response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserAddressResponse {
    private Long id;
    private String address_Name;
    private String city;
    private String province;
    private Long userId;
    private Boolean isDefault;
    private Double latitude;
    private Double longitude;
}