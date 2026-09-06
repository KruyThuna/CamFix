package com.api.Controller;

import com.api.Service.TechnicianLiveLocationService;
import com.api.dto.Request.LocationRequest;
import com.api.dto.Response.LocationResponse;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/technicians/locations")
@RequiredArgsConstructor
public class TechnicianLiveLocationController {

    private final TechnicianLiveLocationService locationService;

    @PostMapping("/update")
    public ResponseEntity<LocationResponse> updateLocation(@Valid @RequestBody LocationRequest request) {
        return ResponseEntity.ok(locationService.updateLocation(request));
    }

    @GetMapping("/{technicianId}")
    public ResponseEntity<LocationResponse> getLocation(@PathVariable Long technicianId) {
        return ResponseEntity.ok(locationService.getLocationByTechnicianId(technicianId));
    }
}