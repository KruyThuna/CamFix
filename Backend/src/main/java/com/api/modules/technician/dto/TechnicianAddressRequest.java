package com.api.modules.technician.dto;


import com.api.modules.technician.entity.Technician;
import java.sql.Timestamp;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.Getter;
import lombok.NoArgsConstructor;

public class TechnicianAddressRequest {

    private double latitude;
    private double longitude;
    private double accuracy;
    private Timestamp last_update;

}
