package com.api.modules.technician.controller;


import com.api.modules.technician.entity.Technician;
import com.api.modules.technician.service.TechnicianLiveLocationService;
import com.api.modules.technician.dto.LocationRequest;
import com.api.modules.technician.dto.LocationResponse;

import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/technicians/locations")
public class TechnicianLiveLocationController {

    private final TechnicianLiveLocationService locationService;

    public TechnicianLiveLocationController(TechnicianLiveLocationService locationService) {
        this.locationService = locationService;
    }

    @PostMapping("/update")
    public ResponseEntity<LocationResponse> updateLocation(@Valid @RequestBody LocationRequest request) {
        return ResponseEntity.ok(locationService.updateLocation(request));
    }

    @GetMapping("/{technicianId}")
    public ResponseEntity<LocationResponse> getLocation(@PathVariable Long technicianId) {
        return ResponseEntity.ok(locationService.getLocationByTechnicianId(technicianId));
    }
}
