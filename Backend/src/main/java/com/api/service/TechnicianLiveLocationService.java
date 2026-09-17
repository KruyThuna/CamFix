package com.api.service;

import com.api.dto.request.LocationRequest;
import com.api.dto.response.LocationResponse;

public interface TechnicianLiveLocationService {

    LocationResponse updateLocation(LocationRequest request);

    LocationResponse getLocationByTechnicianId(Long technicianId);
}