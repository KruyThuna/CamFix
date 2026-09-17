package com.api.service.impl;

import com.api.entity.TechnicianLiveLocation;
import com.api.repository.TechnicianLiveLocationRepository;
import com.api.service.TechnicianLiveLocationService;
import com.api.dto.request.LocationRequest;
import com.api.dto.response.LocationResponse;

import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class TechnicianLiveLocationServiceImpl implements TechnicianLiveLocationService {

	private final TechnicianLiveLocationRepository repository;

	@Transactional
	public LocationResponse updateLocation(LocationRequest request) {
		int rowsUpdated = repository.updateLocationByTechnicianId(
				request.getTechnicianId(),
				request.getLatitude(),
				request.getLongitude(),
				request.getAccuracy());

		TechnicianLiveLocation entity;
		if (rowsUpdated == 0) {
			entity = TechnicianLiveLocation.builder()
					.technicianId(request.getTechnicianId())
					.latitude(request.getLatitude())
					.longitude(request.getLongitude())
					.accuracy(request.getAccuracy())
					.build();
			entity = repository.save(entity);
		} else {
			entity = repository.findByTechnicianId(request.getTechnicianId())
					.orElseThrow(() -> new EntityNotFoundException(
							"Technician location not found for ID: " + request.getTechnicianId()));
		}

		return LocationResponse.fromEntity(entity);
	}

	@Override
	@Transactional(readOnly = true)
	public LocationResponse getLocationByTechnicianId(Long technicianId) {
		TechnicianLiveLocation entity = repository.findByTechnicianId(technicianId)
				.orElseThrow(() -> new EntityNotFoundException(
						"No location data found for technician ID: " + technicianId));

		return LocationResponse.fromEntity(entity);
	}
}