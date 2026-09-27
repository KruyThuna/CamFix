package com.api.service;

import java.util.List;
import java.util.Locale;
import java.util.NoSuchElementException;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import com.api.entity.Technician;
import com.api.entity.TechnicianServiceListing;
import com.api.entity.TechnicianServicePhoto;
import com.api.entity.Users;
import com.api.repository.JobRepository;
import com.api.repository.TechnicianRepository;
import com.api.repository.TechnicianServicePhotoRepository;
import com.api.repository.TechnicianServiceRepository;
import com.api.security.AuthSupport;
import com.api.dto.technician.TechnicianServiceRequest;
import com.api.dto.technician.TechnicianServiceResponse;
import com.api.exception.InvalidCredentialsException;

/**
 * Real per-service listings a technician sets up themselves (title + price),
 * with a live completed-job count computed from {@link com.api.entity.Job} -
 * replaces the old hardcoded "Achievements tab" numbers the customer app used
 * to show for every technician regardless of who they actually were.
 */
@Service
@Transactional
public class TechnicianServiceManager {

    private static final String STATUS_COMPLETED = "COMPLETED";

    private final TechnicianServiceRepository repository;
    private final TechnicianRepository technicianRepository;
    private final JobRepository jobRepository;
    private final AuthSupport authSupport;
    private final PublicTechnicianService publicTechnicianService;
    private final TechnicianServicePhotoRepository photoRepository;

    public TechnicianServiceManager(TechnicianServiceRepository repository,
            TechnicianRepository technicianRepository,
            JobRepository jobRepository,
            AuthSupport authSupport,
            PublicTechnicianService publicTechnicianService,
            TechnicianServicePhotoRepository photoRepository) {
        this.repository = repository;
        this.technicianRepository = technicianRepository;
        this.jobRepository = jobRepository;
        this.authSupport = authSupport;
        this.publicTechnicianService = publicTechnicianService;
        this.photoRepository = photoRepository;
    }

    // --- Public (customer app) ------------------------------------------------

    @Transactional(readOnly = true)
    public List<TechnicianServiceResponse> listPublic(Long technicianId) {
        // Throws 404 unless the technician is approved + not suspended - same
        // visibility rule as the rest of the public directory.
        publicTechnicianService.get(technicianId);
        return repository.findByTechnicianId(technicianId).stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    // --- Self-service (technician app) -----------------------------------------

    @Transactional(readOnly = true)
    public List<TechnicianServiceResponse> listMine(String authorization) {
        Technician me = requireTechnician(authorization);
        return repository.findByTechnicianId(me.getTechnicianId()).stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    public TechnicianServiceResponse create(String authorization, TechnicianServiceRequest req) {
        Technician me = requireTechnician(authorization);
        validate(req);
        TechnicianServiceListing entity = new TechnicianServiceListing();
        entity.setTechnicianId(me.getTechnicianId());
        entity.setTitle(req.getTitle().trim());
        entity.setPrice(req.getPrice());
        entity.setDescription(blankToNull(req.getDescription()));
        return toDto(repository.save(entity));
    }

    public TechnicianServiceResponse update(String authorization, Long id, TechnicianServiceRequest req) {
        Technician me = requireTechnician(authorization);
        validate(req);
        TechnicianServiceListing entity = repository.findByIdAndTechnicianId(id, me.getTechnicianId())
                .orElseThrow(() -> new NoSuchElementException("Service not found: " + id));
        entity.setTitle(req.getTitle().trim());
        entity.setPrice(req.getPrice());
        entity.setDescription(blankToNull(req.getDescription()));
        return toDto(repository.save(entity));
    }

    public void delete(String authorization, Long id) {
        Technician me = requireTechnician(authorization);
        TechnicianServiceListing entity = repository.findByIdAndTechnicianId(id, me.getTechnicianId())
                .orElseThrow(() -> new NoSuchElementException("Service not found: " + id));
        if (photoRepository.existsById(id)) {
            photoRepository.deleteById(id);
        }
        repository.delete(entity);
    }

    // --- Helpers ---------------------------------------------------------------

    private static String blankToNull(String s) {
        return s == null || s.trim().isEmpty() ? null : s.trim();
    }

    private static void validate(TechnicianServiceRequest req) {
        if (req == null || req.getTitle() == null || req.getTitle().trim().isEmpty()) {
            throw new IllegalArgumentException("title is required");
        }
        if (req.getPrice() == null || req.getPrice() < 0) {
            throw new IllegalArgumentException("price must be a non-negative number");
        }
    }

    private Technician requireTechnician(String authorization) {
        Users user = authSupport.currentUser(authorization);
        return technicianRepository.findByUsers_UserId(user.getUserId())
                .orElseThrow(() -> new InvalidCredentialsException("No technician profile for this account"));
    }

    private TechnicianServiceResponse toDto(TechnicianServiceListing s) {
        TechnicianServiceResponse r = new TechnicianServiceResponse();
        r.setId(s.getId());
        r.setTechnicianId(s.getTechnicianId());
        r.setTitle(s.getTitle());
        r.setPrice(s.getPrice());
        r.setDescription(s.getDescription());
        r.setCompletedJobCount(jobRepository.countByTechnicianServiceIdAndStatus(s.getId(), STATUS_COMPLETED));
        if (s.getPhotoContentType() != null) {
            r.setPhotoUrl("/api/technicians/services/" + s.getId() + "/photo?v="
                    + (s.getPhotoVersion() == null ? 0 : s.getPhotoVersion()));
        }
        return r;
    }

    // --- Per-listing photo -------------------------------------------------------

    private static final long MAX_PHOTO_BYTES = 5L * 1024 * 1024;

    public TechnicianServiceResponse uploadPhoto(String authorization, Long id, MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("photo file is required");
        }
        if (file.getSize() > MAX_PHOTO_BYTES) {
            throw new IllegalArgumentException("photo must be 5MB or smaller");
        }
        String contentType = file.getContentType();
        if (contentType == null || !contentType.toLowerCase(Locale.ROOT).startsWith("image/")) {
            throw new IllegalArgumentException("photo must be an image file");
        }
        Technician me = requireTechnician(authorization);
        TechnicianServiceListing entity = repository.findByIdAndTechnicianId(id, me.getTechnicianId())
                .orElseThrow(() -> new NoSuchElementException("Service not found: " + id));
        TechnicianServicePhoto photo = photoRepository.findById(id).orElseGet(TechnicianServicePhoto::new);
        photo.setListingId(id);
        try {
            photo.setData(file.getBytes());
        } catch (java.io.IOException e) {
            throw new IllegalArgumentException("Could not read the uploaded photo");
        }
        photo.setContentType(contentType);
        photoRepository.save(photo);
        entity.setPhotoContentType(contentType);
        entity.setPhotoVersion(System.currentTimeMillis());
        return toDto(repository.save(entity));
    }

    public TechnicianServiceResponse deletePhoto(String authorization, Long id) {
        Technician me = requireTechnician(authorization);
        TechnicianServiceListing entity = repository.findByIdAndTechnicianId(id, me.getTechnicianId())
                .orElseThrow(() -> new NoSuchElementException("Service not found: " + id));
        photoRepository.deleteById(id);
        entity.setPhotoContentType(null);
        entity.setPhotoVersion(System.currentTimeMillis());
        return toDto(repository.save(entity));
    }

    /** Public: the photo bytes, only for an approved technician's listing. */
    @Transactional(readOnly = true)
    public TechnicianServicePhoto publicPhoto(Long listingId) {
        TechnicianServiceListing listing = repository.findById(listingId)
                .orElseThrow(() -> new NoSuchElementException("Service not found: " + listingId));
        publicTechnicianService.get(listing.getTechnicianId()); // 404 unless approved
        return photoRepository.findById(listingId)
                .orElseThrow(() -> new NoSuchElementException("No photo for service " + listingId));
    }
}
