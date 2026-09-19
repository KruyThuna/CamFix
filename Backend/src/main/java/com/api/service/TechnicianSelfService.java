package com.api.service;

import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.NoSuchElementException;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import com.api.entity.Category;
import com.api.entity.Job;
import com.api.entity.ServiceQuote;
import com.api.entity.Technician;
import com.api.entity.TechnicianLiveLocation;
import com.api.entity.Users;
import com.api.repository.CategoryRepository;
import com.api.repository.JobRepository;
import com.api.repository.ServiceQuoteRepository;
import com.api.repository.TechnicianLiveLocationRepository;
import com.api.repository.TechnicianRepository;
import com.api.repository.UserRepository;
import com.api.security.JwtService;
import com.api.dto.auth.AuthResponse;
import com.api.dto.auth.PhoneOtpRequest;
import com.api.dto.booking.ServiceQuoteResponse;
import com.api.dto.booking.SubmitQuoteRequest;
import com.api.dto.response.CallHistoryResponse;
import com.api.dto.technician.TechJobResponse;
import com.api.dto.technician.TechnicianProfileResponse;
import com.api.dto.technician.TechnicianRegisterRequest;
import com.api.exception.EmailAlreadyExistsException;
import com.api.exception.InvalidCredentialsException;

/**
 * Self-service surface for the technician app ({@code /api/technician/**} except
 * the admin-managed list). New technicians land {@code approval_status=PENDING}
 * and stay locked out of jobs until an admin approves them from the console
 * (see {@code AdminService.approveTechnician}).
 *
 * <p>No security filter chain in this project, so each entry point resolves the
 * caller's bearer token here - same pattern as {@code AuthController} /
 * {@code AdminService}. {@code spring.jpa.open-in-view=false} -> the class is
 * {@code @Transactional} so lazy {@code technician.users} / {@code .category}
 * loads succeed during DTO mapping.
 */
@Service
@Transactional
public class TechnicianSelfService {

    private static final String ROLE_TECHNICIAN = "TECHNICIAN";
    private static final String STATUS_ACTIVE = "ACTIVE";
    private static final String STATUS_SUSPENDED = "SUSPENDED";
    private static final String AP_PENDING = "PENDING";
    private static final String AP_APPROVED = "APPROVED";

    private static final String JOB_REQUESTED = "REQUESTED";
    private static final String JOB_ASSIGNED = "ASSIGNED";
    private static final String JOB_ON_THE_WAY = "ON_THE_WAY";
    private static final String JOB_ARRIVED = "ARRIVED";
    private static final String JOB_QUOTE_PENDING = "QUOTE_PENDING";
    private static final String JOB_IN_PROGRESS = "IN_PROGRESS";
    private static final String JOB_COMPLETED = "COMPLETED";
    private static final String QUOTE_STATUS_PENDING = "PENDING";
    private static final String QUOTE_STATUS_REVISED = "REVISED";

    private static final Set<String> AVAILABLE_TOKENS = Set.of("AVAILABLE", "ONLINE", "TRUE", "YES", "1");

    private final UserRepository userRepository;
    private final TechnicianRepository technicianRepository;
    private final CategoryRepository categoryRepository;
    private final TechnicianLiveLocationRepository liveLocationRepository;
    private final JobRepository jobRepository;
    private final ServiceQuoteRepository serviceQuoteRepository;
    private final JwtService jwtService;
    private final OtpService otpService;
    private final PasswordEncoder passwordEncoder;
    private final NotificationDispatcher notifications;
    private final CallService callService;

    public TechnicianSelfService(UserRepository userRepository,
            TechnicianRepository technicianRepository,
            CategoryRepository categoryRepository,
            TechnicianLiveLocationRepository liveLocationRepository,
            JobRepository jobRepository,
            ServiceQuoteRepository serviceQuoteRepository,
            JwtService jwtService,
            OtpService otpService,
            PasswordEncoder passwordEncoder,
            NotificationDispatcher notifications,
            CallService callService) {
        this.userRepository = userRepository;
        this.technicianRepository = technicianRepository;
        this.categoryRepository = categoryRepository;
        this.liveLocationRepository = liveLocationRepository;
        this.jobRepository = jobRepository;
        this.serviceQuoteRepository = serviceQuoteRepository;
        this.jwtService = jwtService;
        this.otpService = otpService;
        this.passwordEncoder = passwordEncoder;
        this.notifications = notifications;
        this.callService = callService;
    }

    // --- Registration / auth ------------------------------------------------

    /** Send a phone OTP ahead of registration - the code from this call must be
     *  passed back as {@code otpCode} in {@link #register}. Rejects a number
     *  that's already registered so a doomed registration never burns an SMS. */
    public Map<String, Object> requestPhoneOtp(PhoneOtpRequest req) {
        String raw = req == null ? null : req.getPhoneNumber();
        requireText(raw, "phoneNumber is required");
        String phone = canonicalPhone(raw.trim());
        if (userRepository.existsByPhoneNumber(phone)) {
            throw new IllegalArgumentException("Phone number already in use: " + phone);
        }
        String code = otpService.issuePhone(phone);
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("message", "OTP sent to " + phone);
        if (otpService.isExposeCode() && code != null) {
            body.put("devCode", code);
        }
        return body;
    }

    public AuthResponse register(TechnicianRegisterRequest req) {
        requireText(req.getFirstName(), "firstName is required");
        requireText(req.getLastName(), "lastName is required");
        requireText(req.getEmail(), "email is required");
        requireText(req.getPassword(), "password is required");
        requireText(req.getPhoneNumber(), "phoneNumber is required");
        requireText(req.getCategory(), "category is required");
        requireText(req.getServiceArea(), "serviceArea is required");
        requireText(req.getOtpCode(), "otpCode is required - request one via /phone/request-otp first");
        if (req.getPassword().trim().length() < 6) {
            throw new IllegalArgumentException("password must be at least 6 characters");
        }

        String email = req.getEmail().trim().toLowerCase(Locale.ROOT);
        String phone = canonicalPhone(req.getPhoneNumber().trim());
        if (userRepository.existsByEmail(email)) {
            throw new EmailAlreadyExistsException("Email already registered: " + email);
        }
        if (userRepository.existsByPhoneNumber(phone)) {
            throw new IllegalArgumentException("Phone number already in use: " + phone);
        }
        if (!otpService.verify(phone, req.getOtpCode().trim())) {
            throw new InvalidCredentialsException("Invalid or expired phone verification code");
        }

        Users user = new Users();
        user.setFirstName(req.getFirstName().trim());
        user.setLastName(req.getLastName().trim());
        user.setEmail(email);
        user.setPhoneNumber(phone);
        user.setPassword(passwordEncoder.encode(req.getPassword()));
        user.setRole(ROLE_TECHNICIAN);
        user.setStatus(STATUS_ACTIVE);
        user = userRepository.save(user);

        Technician tech = new Technician();
        tech.setUsers(user);
        tech.setCategory(findOrCreateCategory(req.getCategory()));
        tech.setBusinessName((user.getFirstName() + " " + user.getLastName()).trim());
        tech.setExperienceYear(0);
        tech.setVerified(false);
        tech.setApprovalStatus(AP_PENDING);
        tech.setRatingCount(0);
        tech.setServiceArea(req.getServiceArea().trim());
        tech.setAvailabilityStatus("OFFLINE");
        technicianRepository.save(tech);

        return new AuthResponse(
                "Registration received - an admin will review your account",
                jwtService.generateToken(user.getEmail()));
    }

    public AuthResponse verifyPhoneOtp(String phoneNumber, String code) {
        requireText(phoneNumber, "phoneNumber is required");
        requireText(code, "code is required");
        String phone = canonicalPhone(phoneNumber);
        if (!otpService.verify(phone, code.trim())) {
            throw new InvalidCredentialsException("Invalid or expired code");
        }
        Users user = userRepository.findByPhoneNumber(phone)
                .orElseThrow(() -> new InvalidCredentialsException(
                        "No technician account for this number - register first"));
        return new AuthResponse("Phone login successful", jwtService.generateToken(user.getEmail()));
    }

    // --- Profile -----------------------------------------------------------

    @Transactional(readOnly = true)
    public TechnicianProfileResponse me(String authorization) {
        return toDto(requireTechnician(authorization));
    }

    public TechnicianProfileResponse updateProfile(String authorization, Map<String, Object> fields) {
        Technician tech = requireTechnician(authorization);
        Users user = tech.getUsers();
        if (fields != null) {
            str(fields.get("firstName")).ifPresent(v -> user.setFirstName(v));
            str(fields.get("lastName")).ifPresent(v -> user.setLastName(v));
            str(fields.get("phoneNumber")).ifPresent(v -> {
                String phone = canonicalPhone(v);
                if (!phone.equals(user.getPhoneNumber()) && userRepository.existsByPhoneNumber(phone)) {
                    throw new IllegalArgumentException("Phone number already in use: " + phone);
                }
                user.setPhoneNumber(phone);
            });
            str(fields.get("serviceArea")).ifPresent(tech::setServiceArea);
            str(fields.get("openingHours")).ifPresent(tech::setOpeningHours);
            str(fields.get("about")).ifPresent(tech::setDescription);
            str(fields.get("category")).ifPresent(v -> tech.setCategory(findOrCreateCategory(v)));
            if (!isBlank(user.getFirstName()) || !isBlank(user.getLastName())) {
                tech.setBusinessName((user.getFirstName() + " " + user.getLastName()).trim());
            }
            userRepository.save(user);
        }
        return toDto(technicianRepository.save(tech));
    }

    public TechnicianProfileResponse setAvailability(String authorization, boolean available) {
        Technician tech = requireTechnician(authorization);
        tech.setAvailabilityStatus(available ? "AVAILABLE" : "OFFLINE");
        return toDto(technicianRepository.save(tech));
    }

    private static final long MAX_PHOTO_BYTES = 5L * 1024 * 1024;

    public TechnicianProfileResponse uploadPhoto(String authorization, MultipartFile file) {
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
        Technician tech = requireTechnician(authorization);
        try {
            tech.setPhoto(file.getBytes());
        } catch (java.io.IOException e) {
            throw new IllegalArgumentException("Could not read the uploaded photo");
        }
        tech.setPhotoContentType(contentType);
        return toDto(technicianRepository.save(tech));
    }

    public TechnicianProfileResponse deletePhoto(String authorization) {
        Technician tech = requireTechnician(authorization);
        tech.setPhoto(null);
        tech.setPhotoContentType(null);
        return toDto(technicianRepository.save(tech));
    }

    @Transactional(readOnly = true)
    public Technician photoOwner(Long technicianId) {
        Technician tech = technicianRepository.findById(technicianId)
                .orElseThrow(() -> new NoSuchElementException("Technician not found: " + technicianId));
        if (tech.getPhoto() == null || tech.getPhoto().length == 0) {
            throw new NoSuchElementException("No photo for technician " + technicianId);
        }
        return tech;
    }

    public void pushLocation(String authorization, Double lat, Double lng) {
        if (lat == null || lng == null) {
            throw new IllegalArgumentException("lat and lng are required");
        }
        Technician tech = requireTechnician(authorization);
        Long techId = tech.getTechnicianId();
        TechnicianLiveLocation loc = liveLocationRepository.findByTechnicianId(techId)
                .orElseGet(() -> {
                    TechnicianLiveLocation l = new TechnicianLiveLocation();
                    l.setTechnicianId(techId);
                    return l;
                });
        loc.setLatitude(lat);
        loc.setLongitude(lng);
        liveLocationRepository.save(loc);
    }

    // --- Jobs ------------------------------------------------------------------

    @Transactional(readOnly = true)
    public List<TechJobResponse> myJobs(String authorization, String status) {
        Technician tech = requireTechnician(authorization);
        return jobRepository.findByTechnicianId(tech.getTechnicianId()).stream()
                .filter(j -> isBlank(status) || status.equalsIgnoreCase(j.getStatus()))
                .sorted((a, b) -> Long.compare(nz(b.getId()), nz(a.getId())))
                .map(TechnicianSelfService::toDto)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public TechJobResponse job(String authorization, Long id) {
        Technician tech = requireTechnician(authorization);
        return toDto(ownedJob(tech, id));
    }

    public TechJobResponse setJobStatus(String authorization, Long id, String status) {
        Technician tech = requireTechnician(authorization);
        Job job = ownedJob(tech, id);
        String from = job.getStatus() == null ? "" : job.getStatus().toUpperCase(Locale.ROOT);
        String to = status == null ? "" : status.trim().toUpperCase(Locale.ROOT);

        boolean onTheWay = JOB_ASSIGNED.equals(from) && JOB_ON_THE_WAY.equals(to);
        boolean arrived = JOB_ON_THE_WAY.equals(from) && JOB_ARRIVED.equals(to);
        boolean complete = JOB_IN_PROGRESS.equals(from) && JOB_COMPLETED.equals(to);
        boolean decline = (JOB_ASSIGNED.equals(from) || JOB_ON_THE_WAY.equals(from))
                && JOB_REQUESTED.equals(to);
        if (!onTheWay && !arrived && !complete && !decline) {
            // Note: ARRIVED -> IN_PROGRESS is NOT reachable here anymore - it only
            // happens via BookingService.acceptQuote(), once the customer has
            // accepted a real quote. See submitQuote() below.
            throw new IllegalArgumentException(
                    "A technician can't move a job from " + from + " to " + to);
        }

        job.setStatus(to);
        if (complete) {
            job.setCompletedAt(LocalDateTime.now());
        } else if (decline) {
            job.setTechnicianId(null);
            job.setAssignedAt(null);
        }
        Job saved = jobRepository.save(job);

        Users techUser = tech.getUsers();
        String techName = techUser == null ? null
                : (nullToEmpty(techUser.getFirstName()) + " " + nullToEmpty(techUser.getLastName())).trim();
        notifications.jobUpdateForCustomer(saved, to, techName);
        return toDto(saved);
    }

    /** Technician submits (or revises) an itemized repair quote after inspecting
     *  the job. Only reachable from ARRIVED (first quote) or QUOTE_PENDING (a
     *  revision - either because the customer rejected the last one, or the
     *  technician wants to correct it before a decision is made). */
    public ServiceQuoteResponse submitQuote(String authorization, Long jobId, SubmitQuoteRequest req) {
        Technician tech = requireTechnician(authorization);
        Job job = ownedJob(tech, jobId);
        String from = job.getStatus() == null ? "" : job.getStatus().toUpperCase(Locale.ROOT);
        if (!JOB_ARRIVED.equals(from) && !JOB_QUOTE_PENDING.equals(from)) {
            throw new IllegalArgumentException(
                    "A quote can only be sent once the technician has arrived (job is " + from + ")");
        }

        double inspectionFee = nz(req == null ? null : req.getInspectionFee());
        double laborCost = nz(req == null ? null : req.getLaborCost());
        double partsCost = nz(req == null ? null : req.getPartsCost());
        double travelFee = nz(req == null ? null : req.getTravelFee());
        if (inspectionFee < 0 || laborCost < 0 || partsCost < 0 || travelFee < 0) {
            throw new IllegalArgumentException("Quote amounts must be zero or more");
        }

        // A still-pending quote gets superseded, not left dangling.
        serviceQuoteRepository.findByJobIdAndStatus(jobId, QUOTE_STATUS_PENDING).ifPresent(prev -> {
            prev.setStatus(QUOTE_STATUS_REVISED);
            serviceQuoteRepository.save(prev);
        });
        int nextVersion = serviceQuoteRepository.findTopByJobIdOrderByVersionDesc(jobId)
                .map(q -> q.getVersion() + 1)
                .orElse(1);
        boolean isRevision = nextVersion > 1;

        ServiceQuote quote = new ServiceQuote();
        quote.setJobId(jobId);
        quote.setTechnicianId(tech.getTechnicianId());
        quote.setVersion(nextVersion);
        quote.setInspectionFee(inspectionFee);
        quote.setLaborCost(laborCost);
        quote.setPartsCost(partsCost);
        quote.setTravelFee(travelFee);
        quote.setTotalAmount(inspectionFee + laborCost + partsCost + travelFee);
        quote.setReason(req == null ? null : req.getReason());
        quote.setStatus(QUOTE_STATUS_PENDING);
        ServiceQuote saved = serviceQuoteRepository.save(quote);

        job.setStatus(JOB_QUOTE_PENDING);
        Job savedJob = jobRepository.save(job);
        notifications.quoteSubmittedForCustomer(savedJob, saved.getTotalAmount(), isRevision);

        return BookingService.toQuoteDto(saved);
    }

    @Transactional(readOnly = true)
    public List<ServiceQuoteResponse> jobQuotes(String authorization, Long jobId) {
        Technician tech = requireTechnician(authorization);
        ownedJob(tech, jobId);
        return serviceQuoteRepository.findByJobIdOrderByVersionDesc(jobId).stream()
                .map(BookingService::toQuoteDto)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<CallHistoryResponse> myCalls(String authorization) {
        Technician tech = requireTechnician(authorization);
        return callService.forTechnician(tech.getTechnicianId());
    }

    // --- Auth guard ------------------------------------------------------------

    private Technician requireTechnician(String authorization) {
        String email = jwtService.extractEmail(bearer(authorization));
        if (email == null) {
            throw new InvalidCredentialsException("Not authenticated");
        }
        Users user = userRepository.findByEmail(email)
                .orElseThrow(() -> new InvalidCredentialsException("User not found"));
        return technicianRepository.findByUsers_UserId(user.getUserId())
                .orElseThrow(() -> new NoSuchElementException("No technician profile for this account"));
    }

    private Job ownedJob(Technician tech, Long id) {
        Job job = jobRepository.findById(id)
                .orElseThrow(() -> new NoSuchElementException("Job not found: " + id));
        if (!tech.getTechnicianId().equals(job.getTechnicianId())) {
            throw new NoSuchElementException("Job not found: " + id);
        }
        return job;
    }

    // --- Mapping -------------------------------------------------------------

    private TechnicianProfileResponse toDto(Technician t) {
        Users u = t.getUsers();
        TechnicianProfileResponse r = new TechnicianProfileResponse();
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
        r.setRejectionReason(t.getRejectionReason());
        r.setPhotoUrl(t.getPhoto() != null && t.getPhoto().length > 0
                ? "/api/technician/" + t.getTechnicianId() + "/photo"
                : null);
        liveLocationRepository.findByTechnicianId(t.getTechnicianId()).ifPresent(loc -> {
            r.setLastLat(loc.getLatitude());
            r.setLastLng(loc.getLongitude());
        });
        return r;
    }

    private static TechJobResponse toDto(Job j) {
        TechJobResponse r = new TechJobResponse();
        r.setId(j.getId());
        r.setCustomerName(j.getCustomerName());
        r.setCustomerPhone(j.getCustomerPhone());
        r.setCategory(j.getCategory());
        r.setDescription(j.getDescription());
        r.setAddress(j.getAddress());
        r.setLat(j.getLat());
        r.setLng(j.getLng());
        r.setStatus(j.getStatus());
        r.setCreatedAt(str(j.getCreatedAt()));
        r.setScheduledAt(str(j.getScheduledAt()));
        r.setAssignedAt(str(j.getAssignedAt()));
        r.setCompletedAt(str(j.getCompletedAt()));
        return r;
    }

    private Category findOrCreateCategory(String name) {
        String clean = name.trim();
        return categoryRepository.findByCategoryName(clean)
                .orElseGet(() -> categoryRepository.save(new Category(clean, null, null)));
    }

    private static String effectiveApproval(Technician t) {
        String stored = t.getApprovalStatus();
        if (stored != null && !stored.isBlank()) {
            return stored.trim().toUpperCase(Locale.ROOT);
        }
        return t.isVerified() ? AP_APPROVED : AP_PENDING;
    }

    /** Canonical phone: a leading '+' (if present) then digits only - matches
     *  {@code AuthServiceImpl.normalisePhone}, so an OTP issued via
     *  {@code /api/auth/phone/request-otp} verifies here. */
    private static String canonicalPhone(String raw) {
        return com.api.util.PhoneNumbers.canonicalize(raw);
    }

    private static java.util.Optional<String> str(Object v) {
        if (v == null) {
            return java.util.Optional.empty();
        }
        String s = v.toString().trim();
        return s.isEmpty() ? java.util.Optional.empty() : java.util.Optional.of(s);
    }

    private static String str(LocalDateTime value) {
        return value == null ? null : value.toString();
    }

    private static String bearer(String header) {
        if (header == null) {
            return null;
        }
        return header.regionMatches(true, 0, "Bearer ", 0, 7)
                ? header.substring(7).trim()
                : header.trim();
    }

    private static long nz(Long value) {
        return value == null ? 0L : value;
    }

    private static double nz(Double value) {
        return value == null ? 0.0 : value;
    }

    private static boolean isBlank(String v) {
        return v == null || v.isBlank();
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
