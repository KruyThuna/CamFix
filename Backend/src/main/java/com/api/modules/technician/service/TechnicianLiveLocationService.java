package com.api.modules.technician.service;


import com.api.modules.technician.entity.Technician;
import com.api.modules.technician.dto.LocationRequest;
import com.api.modules.technician.dto.LocationResponse;

public interface TechnicianLiveLocationService {

    LocationResponse updateLocation(LocationRequest request);

    LocationResponse getLocationByTechnicianId(Long technicianId);
}