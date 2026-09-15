package com.api.Service;

import java.util.List;
import java.util.Locale;
import java.util.NoSuchElementException;
import java.util.Set;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.api.Entity.Favorite;
import com.api.Entity.Technician;
import com.api.Entity.Users;
import com.api.Repo.FavoriteRepository;
import com.api.Repo.TechnicianRepository;
import com.api.Security.AuthSupport;
import com.api.dto.Response.FavoriteResponse;

/**
 * A customer's saved/favorited technicians. Same bearer-token-resolves-the-
 * caller pattern as the rest of the app ({@link AuthSupport}) - this used to
 * take {@code userId} as a raw request param, which let any caller read or
 * edit any other customer's favorites.
 */
@Service
@Transactional
public class FavoriteService {

    private static final Set<String> AVAILABLE_TOKENS = Set.of("AVAILABLE", "ONLINE", "TRUE", "YES", "1");

    private final AuthSupport authSupport;
    private final FavoriteRepository favoriteRepository;
    private final TechnicianRepository technicianRepository;

    public FavoriteService(AuthSupport authSupport,
            FavoriteRepository favoriteRepository,
            TechnicianRepository technicianRepository) {
        this.authSupport = authSupport;
        this.favoriteRepository = favoriteRepository;
        this.technicianRepository = technicianRepository;
    }

    @Transactional(readOnly = true)
    public List<FavoriteResponse> mine(String authorization) {
        Users me = authSupport.currentUser(authorization);
        return favoriteRepository.findAllWithTechnicianDetailsByUserId(me.getUserId()).stream()
                .map(FavoriteService::toDto)
                .collect(Collectors.toList());
    }

    public FavoriteResponse add(String authorization, Long technicianId) {
        Users me = authSupport.currentUser(authorization);
        if (technicianId == null) {
            throw new IllegalArgumentException("technicianId is required");
        }
        Technician tech = technicianRepository.findById(technicianId)
                .orElseThrow(() -> new NoSuchElementException("Technician not found: " + technicianId));
        if (favoriteRepository.existsByUser_UserIdAndTechnician_TechnicianId(me.getUserId(), technicianId)) {
            throw new IllegalArgumentException("Technician already in favorites");
        }
        Favorite favorite = new Favorite();
        favorite.setUser(me);
        favorite.setTechnician(tech);
        return toDto(favoriteRepository.save(favorite));
    }

    public void remove(String authorization, Long technicianId) {
        Users me = authSupport.currentUser(authorization);
        favoriteRepository.deleteByUser_UserIdAndTechnician_TechnicianId(me.getUserId(), technicianId);
    }

    @Transactional(readOnly = true)
    public boolean isFavorite(String authorization, Long technicianId) {
        Users me = authSupport.currentUser(authorization);
        return favoriteRepository.existsByUser_UserIdAndTechnician_TechnicianId(me.getUserId(), technicianId);
    }

    private static FavoriteResponse toDto(Favorite f) {
        Technician t = f.getTechnician();
        FavoriteResponse r = new FavoriteResponse();
        r.setId(f.getFavoriteId());
        r.setTechnicianId(t.getTechnicianId());
        r.setTechnicianName(technicianName(t));
        r.setTechnicianPhone(t.getUsers() == null ? null : t.getUsers().getPhoneNumber());
        r.setCategory(t.getCategory() == null ? null : t.getCategory().getCategoryName());
        r.setServiceArea(t.getServiceArea());
        r.setRating(t.getAverageRating() == null ? 0d : t.getAverageRating().doubleValue());
        r.setRatingCount(t.getRatingCount() == null ? 0 : t.getRatingCount());
        r.setPhotoUrl(t.getPhoto() != null && t.getPhoto().length > 0
                ? "/api/technician/" + t.getTechnicianId() + "/photo"
                : null);
        r.setAvailable(AVAILABLE_TOKENS.contains(nz(t.getAvailabilityStatus()).toUpperCase(Locale.ROOT)));
        r.setCreatedAt(f.getCreatedAt() == null ? null : f.getCreatedAt().toString());
        return r;
    }

    private static String technicianName(Technician t) {
        Users u = t.getUsers();
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
