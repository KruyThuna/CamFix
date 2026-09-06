package com.api.Service;

import com.api.dto.Request.LocationRequest;
import com.api.dto.Response.LocationResponse;

public interface TechnicianLiveLocationService {

    LocationResponse updateLocation(LocationRequest request);

    LocationResponse getLocationByTechnicianId(Long technicianId);
}