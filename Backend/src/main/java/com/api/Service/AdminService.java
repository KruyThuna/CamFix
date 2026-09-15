package com.api.Service;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.time.ZoneId;
import java.util.List;
import java.util.Locale;
import java.util.NoSuchElementException;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.api.Entity.Category;
import com.api.Entity.Job;
import com.api.Entity.Technician;
import com.api.Entity.Users;
import com.api.Repo.CategoryRepository;
import com.api.Repo.JobRepository;
import com.api.Repo.TechnicianLiveLocationRepository;
import com.api.Repo.TechnicianRepository;
import com.api.Repo.UserRepository;
import com.api.Security.JwtService;
import com.api.dto.Admin.AdminJobRequest;
import com.api.dto.Admin.AdminJobResponse;
import com.api.dto.Admin.AdminTechnicianRequest;
import com.api.dto.Admin.AdminTechnicianResponse;
import com.api.dto.Admin.DashboardStatsResponse;
import com.api.dto.Admin.TechnicianLocationResponse;
import com.api.exception.EmailAlreadyExistsException;
import com.api.exception.ForbiddenException;
import com.api.exception.InvalidCredentialsException;

/**
 * Backs the {@code /api/admin/**} console. The project has no Spring Security
 * filter chain (see {@code SwaggerConfig} - everything under {@code /api/**} is
 * permitAll), so every entry point re-checks the caller's bearer token here via
 * {@link #requireAdmin(String)}, mirroring {@code AuthController}.
 *
 * <p>{@code spring.jpa.open-in-view=false}, so the class is {@code @Transactional}
 * to keep the session open while lazy {@code technician.users}/{@code .category}
 * associations are read during DTO mapping.
 */
@Service
@Transactional
public class AdminService {

    private static final String ROLE_ADMIN = "ADMIN";
    private static final String ROLE_TECHNICIAN = "TECHNICIAN";
    private static final String STATUS_ACTIVE = "ACTIVE";
    private static final String STATUS_SUSPENDED = "SUSPENDED";

    private static final String AP_PENDING = "PENDING";
    private static final String AP_APPROVED = "APPROVED";
    private static final String AP_REJECTED = "REJECTED";

    private static final String JOB_REQUESTED = "REQUESTED";
    private static final String JOB_ASSIGNED = "ASSIGNED";
    private static final String JOB_ON_THE_WAY = "ON_THE_WAY";
    private static final String JOB_ARRIVED = "ARRIVED";
    private static final String JOB_QUOTE_PENDING = "QUOTE_PENDING";
    private static final String JOB_IN_PROGRESS = "IN_PROGRESS";
    private static final String JOB_COMPLETED = "COMPLETED";
    private static final String JOB_CANCELLED = "CANCELLED";
    private static final Set<String> JOB_STATUSES = Set.of(
            JOB_REQUESTED, JOB_ASSIGNED, JOB_ON_THE_WAY, JOB_ARRIVED, JOB_QUOTE_PENDING,
            JOB_IN_PROGRESS, JOB_COMPLETED, JOB_CANCELLED);
    private static final Set<String> JOB_OPEN = Set.of(
            JOB_REQUESTED, JOB_ASSIGNED, JOB_ON_THE_WAY, JOB_ARRIVED, JOB_QUOTE_PENDING, JOB_IN_PROGRESS);

    private static final Set<String> AVAILABLE_TOKENS = Set.of(
            "AVAILABLE", "ONLINE", "TRUE", "YES", "1");

    private final UserRepository userRepository;
    private final TechnicianRepository technicianRepository;
    private final CategoryRepository categoryRepository;
    private final TechnicianLiveLocationRepository liveLocationRepository;
    private final JobRepository jobRepository;
    private final JwtService jwtService;
    private final PasswordEncoder passwordEncoder;
    private final NotificationDispatcher notifications;

    public AdminService(UserRepository userRepository,
            TechnicianRepository technicianRepository,
            CategoryRepository categoryRepository,
            TechnicianLiveLocationRepository liveLocationRepository,
            JobRepository jobRepository,
            JwtService jwtService,
            PasswordEncoder passwordEncoder,
            NotificationDispatcher notifications) {
        this.userRepository = userRepository;
        this.technicianRepository = technicianRepository;
        this.categoryRepository = categoryRepository;
        this.liveLocationRepository = liveLocationRepository;
        this.jobRepository = jobRepository;
        this.jwtService = jwtService;
        this.passwordEncoder = passwordEncoder;
        this.notifications = notifications;
    }

    // --- Auth guard -------------------------------------------------------------

    /** Resolve the bearer token to a user and require the ADMIN role. */
    public Users requireAdmin(String authorizationHeader) {
        String email = jwtService.extractEmail(bearer(authorizationHeader));
        if (email == null) {
            throw new InvalidCredentialsException("Not authenticated");
        }
        Users user = userRepository.findByEmail(email)
                .orElseThrow(() -> new InvalidCredentialsException("User not found"));
        if (!ROLE_ADMIN.equalsIgnoreCase(nullToEmpty(user.getRole()))) {
            throw new ForbiddenException("Admin access required");
        }
        return user;
    }

    private static String bearer(String header) {
        if (header == null) {
            return null;
        }
        return header.regionMatches(true, 0, "Bearer ", 0, 7)
                ? header.substring(7).trim()
                : header.trim();
    }

    // --- Dashboard -----------------------------------------------------------

    @Transactional(readOnly = true)
    public DashboardStatsResponse stats() {
        List<AdminTechnicianResponse> techs = mapTechnicians(technicianRepository.findAll());

        DashboardStatsResponse s = new DashboardStatsResponse();
        s.setPendingTechnicians(techs.stream().filter(t -> AP_PENDING.equals(t.getApprovalStatus())).count());
        s.setActiveTechnicians(techs.stream()
                .filter(t -> AP_APPROVED.equals(t.getApprovalStatus()) && STATUS_ACTIVE.equals(t.getAccountStatus()))
                .count());
        s.setSuspendedTechnicians(techs.stream().filter(t -> STATUS_SUSPENDED.equals(t.getAccountStatus())).count());

        s.setOpenJobs(jobRepository.countByStatusIn(List.copyOf(JOB_OPEN)));
        s.setUnassignedJobs(jobRepository.countByStatus(JOB_REQUESTED));
        s.setCompletedJobs(jobRepository.countByStatus(JOB_COMPLETED));
        return s;
    }

    // --- Technicians: reads --------------------------------------------------

    @Transactional(readOnly = true)
    public List<AdminTechnicianResponse> listTechnicians(String approval, String account,
            String category, String q) {
        String needle = q == null ? "" : q.trim().toLowerCase(Locale.ROOT);
        return mapTechnicians(technicianRepository.findAll()).stream()
                .filter(t -> isBlank(approval) || approval.equalsIgnoreCase(t.getApprovalStatus()))
                .filter(t -> isBlank(account) || account.equalsIgnoreCase(t.getAccountStatus()))
                .filter(t -> isBlank(category) || category.equalsIgnoreCase(t.getCategory()))
                .filter(t -> needle.isEmpty() || matches(t, needle))
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public AdminTechnicianResponse getTechnician(Long id) {
        return toDto(loadTechnician(id));
    }

    @Transactional(readOnly = true)
    public List<TechnicianLocationResponse> technicianLocations() {
        return technicianRepository.findAll().stream()
                .map(t -> {
                    AdminTechnicianResponse dto = toDto(t);
                    if (!AP_APPROVED.equals(dto.getApprovalStatus())
                            || !STATUS_ACTIVE.equals(dto.getAccountStatus())
                            || dto.getLastLat() == null || dto.getLastLng() == null) {
                        return null;
                    }
                    TechnicianLocationResponse loc = new TechnicianLocationResponse();
                    loc.setId(dto.getId());
                    loc.setName((dto.getFirstName() + " " + dto.getLastName()).trim());
                    loc.setCategory(dto.getCategory());
                    loc.setLat(dto.getLastLat());
                    loc.setLng(dto.getLastLng());
                    loc.setAvailable(dto.isAvailable());
                    loc.setLastLocationAt(dto.getLastLocationAt());
                    return loc;
                })
                .filter(l -> l != null)
                .collect(Collectors.toList());
    }

    // --- Technicians: writes -----------------------------------------------

    public AdminTechnicianResponse createTechnician(AdminTechnicianRequest req) {
        requireText(req.getFirstName(), "firstName is required");
        requireText(req.getLastName(), "lastName is required");
        requireText(req.getEmail(), "email is required");
        requireText(req.getPhoneNumber(), "phoneNumber is required");
        requireText(req.getCategory(), "category is required");
        requireText(req.getServiceArea(), "serviceArea is required");

        String email = req.getEmail().trim().toLowerCase(Locale.ROOT);
        String phone = req.getPhoneNumber().trim();
        if (userRepository.existsByEmail(email)) {
            throw new EmailAlreadyExistsException("Email already registered: " + email);
        }
        if (userRepository.existsByPhoneNumber(phone)) {
            throw new IllegalArgumentException("Phone number already in use: " + phone);
        }

        Users user = new Users();
        user.setFirstName(req.getFirstName().trim());
        user.setLastName(req.getLastName().trim());
        user.setEmail(email);
        user.setPhoneNumber(phone);
        user.setPassword(passwordEncoder.encode("tech-" + UUID.randomUUID()));
        user.setRole(ROLE_TECHNICIAN);
        user.setStatus(STATUS_ACTIVE);
        user = userRepository.save(user);

        Technician tech = new Technician();
        tech.setUsers(user);
        tech.setCategory(findOrCreateCategory(req.getCategory()));
        tech.setBusinessName((req.getFirstName().trim() + " " + req.getLastName().trim()).trim());
        tech.setExperienceYear(0);
        tech.setVerified(false);
        tech.setApprovalStatus(AP_PENDING);
        tech.setRatingCount(0);
        applyEditableFields(tech, req);
        return toDto(technicianRepository.save(tech));
    }

    public AdminTechnicianResponse updateTechnician(Long id, AdminTechnicianRequest req) {
        Technician tech = loadTechnician(id);
        Users user = tech.getUsers();

        if (!isBlank(req.getFirstName())) {
            user.setFirstName(req.getFirstName().trim());
        }
        if (!isBlank(req.getLastName())) {
            user.setLastName(req.getLastName().trim());
        }
        if (!isBlank(req.getEmail())) {
            String email = req.getEmail().trim().toLowerCase(Locale.ROOT);
            if (!email.equals(user.getEmail()) && userRepository.existsByEmail(email)) {
                throw new EmailAlreadyExistsException("Email already registered: " + email);
            }
            user.setEmail(email);
        }
        if (!isBlank(req.getPhoneNumber())) {
            String phone = req.getPhoneNumber().trim();
            if (!phone.equals(user.getPhoneNumber()) && userRepository.existsByPhoneNumber(phone)) {
                throw new IllegalArgumentException("Phone number already in use: " + phone);
            }
            user.setPhoneNumber(phone);
        }
        userRepository.save(user);

        if (!isBlank(req.getCategory())) {
            tech.setCategory(findOrCreateCategory(req.getCategory()));
        }
        if (!isBlank(req.getFirstName()) || !isBlank(req.getLastName())) {
            tech.setBusinessName((user.getFirstName() + " " + user.getLastName()).trim());
        }
        applyEditableFields(tech, req);
        return toDto(technicianRepository.save(tech));
    }

    public void deleteTechnician(Long id) {
        Technician tech = loadTechnician(id);
        liveLocationRepository.findByTechnicianId(tech.getTechnicianId())
                .ifPresent(liveLocationRepository::delete);
        technicianRepository.delete(tech);
        // The backing users row is intentionally left in place: other tables
        // (favorites, call_history, reviews) may still reference it. It no
        // longer appears in the console because that lists technician rows.
    }

    public AdminTechnicianResponse approveTechnician(Long id) {
        Technician tech = loadTechnician(id);
        tech.setApprovalStatus(AP_APPROVED);
        tech.setVerified(true);
        tech.setApprovedAt(LocalDateTime.now());
        tech.setRejectionReason(null);
        tech.getUsers().setStatus(STATUS_ACTIVE);
        userRepository.save(tech.getUsers());
        return toDto(technicianRepository.save(tech));
    }

    public AdminTechnicianResponse rejectTechnician(Long id, String reason) {
        Technician tech = loadTechnician(id);
        tech.setApprovalStatus(AP_REJECTED);
        tech.setVerified(false);
        tech.setApprovedAt(null);
        tech.setRejectionReason(isBlank(reason) ? null : reason.trim());
        return toDto(technicianRepository.save(tech));
    }

    public AdminTechnicianResponse suspendTechnician(Long id) {
        Technician tech = loadTechnician(id);
        tech.getUsers().setStatus(STATUS_SUSPENDED);
        userRepository.save(tech.getUsers());
        return toDto(tech);
    }

    public AdminTechnicianResponse reactivateTechnician(Long id) {
        Technician tech = loadTechnician(id);
        tech.getUsers().setStatus(STATUS_ACTIVE);
        userRepository.save(tech.getUsers());
        return toDto(tech);
    }

    // --- Jobs --------------------------------------------------------------

    @Transactional(readOnly = true)
    public List<AdminJobResponse> listJobs(String status, Long technicianId, String q) {
        String needle = q == null ? "" : q.trim().toLowerCase(Locale.ROOT);
        return jobRepository.findAll().stream()
                .filter(j -> isBlank(status) || status.equalsIgnoreCase(j.getStatus()))
                .filter(j -> technicianId == null || technicianId.equals(j.getTechnicianId()))
                .filter(j -> needle.isEmpty() || jobMatches(j, needle))
                .sorted((a, b) -> Long.compare(nz(b.getId()), nz(a.getId())))
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public AdminJobResponse getJob(Long id) {
        return toDto(loadJob(id));
    }

    public AdminJobResponse createJob(AdminJobRequest req) {
        requireText(req.getCustomerName(), "customerName is required");
        requireText(req.getCustomerPhone(), "customerPhone is required");
        requireText(req.getCategory(), "category is required");
        requireText(req.getDescription(), "description is required");

        Job job = new Job();
        job.setStatus(JOB_REQUESTED);
        applyEditableFields(job, req);
        return toDto(jobRepository.save(job));
    }

    public AdminJobResponse updateJob(Long id, AdminJobRequest req) {
        Job job = loadJob(id);
        requireText(req.getCustomerName(), "customerName is required");
        requireText(req.getCustomerPhone(), "customerPhone is required");
        requireText(req.getCategory(), "category is required");
        requireText(req.getDescription(), "description is required");
        applyEditableFields(job, req);
        return toDto(jobRepository.save(job));
    }

    public AdminJobResponse assignJob(Long id, Long technicianId) {
        if (technicianId == null) {
            throw new IllegalArgumentException("technicianId is required");
        }
        Job job = loadJob(id);
        Technician tech = loadTechnician(technicianId); // 404 if unknown
        job.setTechnicianId(technicianId);
        if (JOB_REQUESTED.equals(job.getStatus()) || job.getStatus() == null) {
            job.setStatus(JOB_ASSIGNED);
        }
        job.setAssignedAt(LocalDateTime.now());
        Job saved = jobRepository.save(job);

        Users techUser = tech.getUsers();
        notifications.jobAssignedToTechnician(techUser == null ? null : techUser.getUserId(), saved);
        notifications.jobUpdateForCustomer(saved, JOB_ASSIGNED, technicianDisplayName(tech));
        return toDto(saved);
    }

    public AdminJobResponse changeJobStatus(Long id, String status) {
        String next = status == null ? "" : status.trim().toUpperCase(Locale.ROOT);
        if (!JOB_STATUSES.contains(next)) {
            throw new IllegalArgumentException("Unknown job status: " + status);
        }
        Job job = loadJob(id);
        job.setStatus(next);
        switch (next) {
            case JOB_REQUESTED -> {
                job.setTechnicianId(null);
                job.setAssignedAt(null);
            }
            case JOB_ASSIGNED -> {
                if (job.getAssignedAt() == null) {
                    job.setAssignedAt(LocalDateTime.now());
                }
            }
            case JOB_COMPLETED -> job.setCompletedAt(LocalDateTime.now());
            default -> {
                /* IN_PROGRESS / CANCELLED: no timestamp side-effects */
            }
        }
        Job saved = jobRepository.save(job);
        notifications.jobUpdateForCustomer(saved, next, jobTechnicianName(saved));
        return toDto(saved);
    }

    public AdminJobResponse cancelJob(Long id) {
        Job job = loadJob(id);
        job.setStatus(JOB_CANCELLED);
        Job saved = jobRepository.save(job);
        notifications.jobUpdateForCustomer(saved, JOB_CANCELLED, jobTechnicianName(saved));
        return toDto(saved);
    }

    /** Best-effort display name for a job's assigned technician (for notification copy). */
    private String jobTechnicianName(Job job) {
        if (job.getTechnicianId() == null) {
            return null;
        }
        return technicianRepository.findById(job.getTechnicianId())
                .map(AdminService::technicianDisplayName)
                .orElse(null);
    }

    private static String technicianDisplayName(Technician t) {
        Users u = t.getUsers();
        if (u == null) {
            return t.getBusinessName();
        }
        String n = (nullToEmpty(u.getFirstName()) + " " + nullToEmpty(u.getLastName())).trim();
        return n.isEmpty() ? t.getBusinessName() : n;
    }

    // --- Mapping ---------------------------------------------------------------

    private List<AdminTechnicianResponse> mapTechnicians(List<Technician> technicians) {
        return technicians.stream().map(this::toDto).collect(Collectors.toList());
    }

    private AdminTechnicianResponse toDto(Technician t) {
        Users u = t.getUsers();
        AdminTechnicianResponse r = new AdminTechnicianResponse();
        r.setId(t.getTechnicianId());
        r.setFirstName(u == null ? "" : nullToEmpty(u.getFirstName()));
        r.setLastName(u == null ? "" : nullToEmpty(u.getLastName()));
        r.setEmail(u == null ? null : u.getEmail());
        r.setPhoneNumber(u == null ? null : u.getPhoneNumber());
        r.setCategory(t.getCategory() == null ? null : t.getCategory().getCategoryName());
        r.setServiceArea(t.getServiceArea());
        r.setAbout(t.getDescription());
        r.setOpeningHours(t.getOpeningHours());
        r.setRating(t.getAverageRating() == null ? 0d : t.getAverageRating().doubleValue());
        r.setRatingCount(t.getRatingCount() == null ? 0 : t.getRatingCount());
        r.setApprovalStatus(effectiveApproval(t));
        r.setAccountStatus(STATUS_SUSPENDED.equalsIgnoreCase(u == null ? "" : nullToEmpty(u.getStatus()))
                ? STATUS_SUSPENDED : STATUS_ACTIVE);
        r.setAvailable(AVAILABLE_TOKENS.contains(nullToEmpty(t.getAvailabilityStatus()).toUpperCase(Locale.ROOT)));
        r.setCreatedAt(str(t.getCreatedAt()));
        r.setApprovedAt(str(t.getApprovedAt()));
        r.setRejectionReason(t.getRejectionReason());

        liveLocationRepository.findByTechnicianId(t.getTechnicianId()).ifPresent(loc -> {
            r.setLastLat(loc.getLatitude());
            r.setLastLng(loc.getLongitude());
            r.setLastLocationAt(str(loc.getLastUpdate()));
        });
        return r;
    }

    private AdminJobResponse toDto(Job j) {
        AdminJobResponse r = new AdminJobResponse();
        r.setId(j.getId());
        r.setCustomerName(j.getCustomerName());
        r.setCustomerPhone(j.getCustomerPhone());
        r.setCustomerUserId(j.getCustomerUserId());
        r.setCategory(j.getCategory());
        r.setDescription(j.getDescription());
        r.setAddress(j.getAddress());
        r.setLat(j.getLat());
        r.setLng(j.getLng());
        r.setStatus(j.getStatus());
        r.setTechnicianId(j.getTechnicianId());
        r.setCreatedAt(str(j.getCreatedAt()));
        r.setScheduledAt(str(j.getScheduledAt()));
        r.setAssignedAt(str(j.getAssignedAt()));
        r.setCompletedAt(str(j.getCompletedAt()));
        r.setNotes(j.getNotes());

        if (j.getTechnicianId() != null) {
            technicianRepository.findById(j.getTechnicianId()).ifPresent(t -> {
                Users u = t.getUsers();
                if (u != null) {
                    r.setTechnicianName((nullToEmpty(u.getFirstName()) + " " + nullToEmpty(u.getLastName())).trim());
                    r.setTechnicianPhone(u.getPhoneNumber());
                } else {
                    r.setTechnicianName(t.getBusinessName());
                }
            });
        }
        return r;
    }

    private void applyEditableFields(Technician tech, AdminTechnicianRequest req) {
        if (req.getServiceArea() != null) {
            tech.setServiceArea(req.getServiceArea().trim());
        }
        if (req.getOpeningHours() != null) {
            tech.setOpeningHours(blankToNull(req.getOpeningHours()));
        }
        if (req.getAbout() != null) {
            tech.setDescription(blankToNull(req.getAbout()));
        }
        if (req.getRating() != null) {
            double clamped = Math.max(0d, Math.min(5d, req.getRating()));
            tech.setAverageRating(BigDecimal.valueOf(clamped));
        }
        if (req.getAvailable() != null) {
            tech.setAvailabilityStatus(req.getAvailable() ? "AVAILABLE" : "OFFLINE");
        }
    }

    private void applyEditableFields(Job job, AdminJobRequest req) {
        job.setCustomerName(req.getCustomerName().trim());
        job.setCustomerPhone(req.getCustomerPhone().trim());
        job.setCustomerUserId(req.getCustomerUserId());
        job.setCategory(req.getCategory().trim());
        job.setDescription(req.getDescription().trim());
        job.setAddress(blankToNull(req.getAddress()));
        job.setLat(req.getLat());
        job.setLng(req.getLng());
        job.setNotes(blankToNull(req.getNotes()));
        job.setScheduledAt(parseInstant(req.getScheduledAt()));
    }

    private Category findOrCreateCategory(String name) {
        String clean = name.trim();
        return categoryRepository.findByCategoryName(clean)
                .orElseGet(() -> categoryRepository.save(new Category(clean, null, null)));
    }

    private Technician loadTechnician(Long id) {
        return technicianRepository.findById(id)
                .orElseThrow(() -> new NoSuchElementException("Technician not found: " + id));
    }

    private Job loadJob(Long id) {
        return jobRepository.findById(id)
                .orElseThrow(() -> new NoSuchElementException("Job not found: " + id));
    }

    private static String effectiveApproval(Technician t) {
        String stored = t.getApprovalStatus();
        if (stored != null && !stored.isBlank()) {
            return stored.trim().toUpperCase(Locale.ROOT);
        }
        return t.isVerified() ? AP_APPROVED : AP_PENDING;
    }

    private static boolean matches(AdminTechnicianResponse t, String needle) {
        return contains(t.getFirstName() + " " + t.getLastName(), needle)
                || contains(t.getEmail(), needle)
                || contains(t.getPhoneNumber(), needle);
    }

    private static boolean jobMatches(Job j, String needle) {
        return contains(j.getCustomerName(), needle)
                || contains(j.getCustomerPhone(), needle)
                || contains(j.getCategory(), needle);
    }

    private static boolean contains(String haystack, String needleLower) {
        return haystack != null && haystack.toLowerCase(Locale.ROOT).contains(needleLower);
    }

    private static LocalDateTime parseInstant(String raw) {
        if (raw == null || raw.isBlank()) {
            return null;
        }
        String s = raw.trim();
        try {
            return OffsetDateTime.parse(s).atZoneSameInstant(ZoneId.systemDefault()).toLocalDateTime();
        } catch (RuntimeException ignored) {
            // not an offset date-time
        }
        try {
            return Instant.parse(s).atZone(ZoneId.systemDefault()).toLocalDateTime();
        } catch (RuntimeException ignored) {
            // not an instant
        }
        try {
            return LocalDateTime.parse(s);
        } catch (RuntimeException ignored) {
            throw new IllegalArgumentException("scheduledAt must be an ISO-8601 date-time");
        }
    }

    private static String str(LocalDateTime value) {
        return value == null ? null : value.toString();
    }

    private static long nz(Long value) {
        return value == null ? 0L : value;
    }

    private static boolean isBlank(String v) {
        return v == null || v.isBlank();
    }

    private static String blankToNull(String v) {
        return (v == null || v.isBlank()) ? null : v.trim();
    }

    private static String nullToEmpty(String v) {
        return v == null ? "" : v;
    }

    private static void requireText(String value, String message) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException(message);
        }
    }
}
