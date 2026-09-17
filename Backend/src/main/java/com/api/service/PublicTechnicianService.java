package com.api.service;

import java.util.List;
import java.util.Locale;
import java.util.NoSuchElementException;
import java.util.Set;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.api.entity.Technician;
import com.api.repository.TechnicianLiveLocationRepository;
import com.api.repository.TechnicianRepository;
import com.api.dto.response.PublicTechnicianResponse;

/**
 * Read-only technician directory for the customer app - a newly registered
 * technician shows up here as soon as an admin approves them (the same
 * approved+active check {@code BookingService.resolveAssignee} uses), with no
 * separate "publish" step. Deliberately its own small service rather than
 * reusing the broken {@code TechnicianService}/{@code TechnicianController}
 * (raw entities, no approval filter, unrelated bugs) - this is a clean read
 * path built next to it, not a fix of it.
 */
@Service
@Transactional(readOnly = true)
public class PublicTechnicianService {

    private static final String AP_APPROVED = "APPROVED";
    private static final String STATUS_SUSPENDED = "SUSPENDED";
    private static final Set<String> AVAILABLE_TOKENS = Set.of("AVAILABLE", "ONLINE", "TRUE", "YES", "1");

    private final TechnicianRepository technicianRepository;
    private final TechnicianLiveLocationRepository liveLocationRepository;

    public PublicTechnicianService(TechnicianRepository technicianRepository,
            TechnicianLiveLocationRepository liveLocationRepository) {
        this.technicianRepository = technicianRepository;
        this.liveLocationRepository = liveLocationRepository;
    }

    public List<PublicTechnicianResponse> list(String category) {
        String wanted = category == null ? null : category.trim();
        return technicianRepository.findAll().stream()
                .filter(PublicTechnicianService::isVisible)
                .filter(t -> wanted == null || wanted.isEmpty()
                        || (t.getCategory() != null && wanted.equalsIgnoreCase(t.getCategory().getCategoryName())))
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    public PublicTechnicianResponse get(Long id) {
        Technician t = technicianRepository.findById(id)
                .filter(PublicTechnicianService::isVisible)
                .orElseThrow(() -> new NoSuchElementException("Technician not found: " + id));
        return toDto(t);
    }

    /** Same "can this technician actually take jobs" rule as
     *  {@code BookingService.resolveAssignee} - approved and not suspended. */
    private static boolean isVisible(Technician t) {
        boolean approved = AP_APPROVED.equalsIgnoreCase(
                t.getApprovalStatus() == null
                        ? (t.isVerified() ? AP_APPROVED : "")
                        : t.getApprovalStatus());
        boolean active = t.getUsers() == null
                || !STATUS_SUSPENDED.equalsIgnoreCase(nz(t.getUsers().getStatus()));
        return approved && active;
    }

    private PublicTechnicianResponse toDto(Technician t) {
        PublicTechnicianResponse r = new PublicTechnicianResponse();
        r.setId(t.getTechnicianId());
        r.setName(technicianName(t));
        r.setCategory(t.getCategory() == null ? null : t.getCategory().getCategoryName());
        r.setServiceArea(t.getServiceArea());
        r.setAbout(t.getDescription());
        r.setOpeningHours(t.getOpeningHours());
        r.setPhone(t.getUsers() == null ? null : t.getUsers().getPhoneNumber());
        r.setRating(t.getAverageRating() == null ? 0d : t.getAverageRating().doubleValue());
        r.setRatingCount(t.getRatingCount() == null ? 0 : t.getRatingCount());
        r.setPhotoUrl(t.getPhoto() != null && t.getPhoto().length > 0
                ? "/api/technician/" + t.getTechnicianId() + "/photo"
                : null);
        r.setAvailable(AVAILABLE_TOKENS.contains(nz(t.getAvailabilityStatus()).toUpperCase(Locale.ROOT)));
        r.setExperienceYear(t.getExperienceYear());
        liveLocationRepository.findByTechnicianId(t.getTechnicianId()).ifPresent(loc -> {
            r.setLat(loc.getLatitude());
            r.setLng(loc.getLongitude());
        });
        return r;
    }

    private static String technicianName(Technician t) {
        var u = t.getUsers();
        if (u == null) {
            return t.getBusinessName();
        }
        String n = (nz(u.getFirstName()) + " " + nz(u.getLastName())).trim();
        return n.isEmpty() ? t.getBusinessName() : n;
    }

    private static String nz(String v) {
        return v == null ? "" : v;
    }
}
