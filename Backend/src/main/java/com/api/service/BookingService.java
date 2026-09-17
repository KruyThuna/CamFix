package com.api.service;

import java.time.Instant;
import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.time.ZoneId;
import java.util.List;
import java.util.Locale;
import java.util.NoSuchElementException;
import java.util.Set;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.api.entity.Job;
import com.api.entity.ServiceQuote;
import com.api.entity.Technician;
import com.api.entity.Users;
import com.api.repository.JobRepository;
import com.api.repository.ServiceQuoteRepository;
import com.api.repository.TechnicianLiveLocationRepository;
import com.api.repository.TechnicianRepository;
import com.api.security.AuthSupport;
import com.api.dto.booking.BookingRequest;
import com.api.dto.booking.BookingResponse;
import com.api.dto.booking.ServiceQuoteResponse;

/**
 * Turns a customer's "Confirm booking" tap into a real {@code job} row and the
 * notifications that go with it. Jobs land {@code REQUESTED} (an admin assigns a
 * technician from the console) unless the request names a valid, approved
 * technician to dispatch to directly.
 */
@Service
@Transactional
public class BookingService {

    private static final String STATUS_REQUESTED = "REQUESTED";
    private static final String STATUS_ASSIGNED = "ASSIGNED";
    private static final String STATUS_ARRIVED = "ARRIVED";
    private static final String STATUS_QUOTE_PENDING = "QUOTE_PENDING";
    private static final String STATUS_IN_PROGRESS = "IN_PROGRESS";
    private static final String AP_APPROVED = "APPROVED";

    private static final String TYPE_IMMEDIATE = "IMMEDIATE";
    private static final String TYPE_SCHEDULED = "SCHEDULED";

    private static final String QUOTE_PENDING = "PENDING";
    private static final String QUOTE_ACCEPTED = "ACCEPTED";
    private static final String QUOTE_REJECTED = "REJECTED";

    /** Statuses the customer can still back out of from the tracking screen. */
    private static final Set<String> CANCELLABLE = Set.of(
            STATUS_REQUESTED, STATUS_ASSIGNED, "ON_THE_WAY", STATUS_ARRIVED, STATUS_QUOTE_PENDING);

    private final AuthSupport authSupport;
    private final JobRepository jobRepository;
    private final TechnicianRepository technicianRepository;
    private final TechnicianLiveLocationRepository liveLocationRepository;
    private final ServiceQuoteRepository serviceQuoteRepository;
    private final ServicePriceService servicePriceService;
    private final NotificationDispatcher notifications;

    public BookingService(AuthSupport authSupport,
            JobRepository jobRepository,
            TechnicianRepository technicianRepository,
            TechnicianLiveLocationRepository liveLocationRepository,
            ServiceQuoteRepository serviceQuoteRepository,
            ServicePriceService servicePriceService,
            NotificationDispatcher notifications) {
        this.authSupport = authSupport;
        this.jobRepository = jobRepository;
        this.technicianRepository = technicianRepository;
        this.liveLocationRepository = liveLocationRepository;
        this.serviceQuoteRepository = serviceQuoteRepository;
        this.servicePriceService = servicePriceService;
        this.notifications = notifications;
    }

    public BookingResponse create(String authorization, BookingRequest req) {
        Users me = authSupport.currentUser(authorization);
        if (req == null || isBlank(req.getCategory())) {
            throw new IllegalArgumentException("category is required");
        }

        Job job = new Job();
        job.setCustomerUserId(me.getUserId());
        job.setCustomerName(displayName(me));
        job.setCustomerPhone(nz(me.getPhoneNumber()));
        job.setCategory(req.getCategory().trim());
        job.setDescription(buildDescription(req));
        job.setAddress(blankToNull(req.getAddress()));
        job.setLat(req.getLat());
        job.setLng(req.getLng());
        job.setScheduledAt(parseInstant(req.getScheduledAt()));
        job.setNotes(blankToNull(req.getNote()));
        job.setBookingType(normalizeBookingType(req.getBookingType()));
        job.setStartingPrice(servicePriceService.startingPriceForCategoryName(job.getCategory()));

        Technician assignee = resolveAssignee(req.getTechnicianId());
        if (assignee != null) {
            job.setStatus(STATUS_ASSIGNED);
            job.setTechnicianId(assignee.getTechnicianId());
            job.setAssignedAt(LocalDateTime.now());
        } else {
            job.setStatus(STATUS_REQUESTED);
        }

        job = jobRepository.save(job);

        if (assignee != null) {
            Users techUser = assignee.getUsers();
            notifications.jobAssignedToTechnician(techUser == null ? null : techUser.getUserId(), job);
            notifications.jobUpdateForCustomer(job, STATUS_ASSIGNED, technicianName(assignee));
        } else {
            notifications.bookingRequested(me.getUserId(), job);
        }

        return toResponse(job);
    }

    @Transactional(readOnly = true)
    public List<BookingResponse> mine(String authorization) {
        Users me = authSupport.currentUser(authorization);
        return jobRepository.findAll().stream()
                .filter(j -> me.getUserId().equals(j.getCustomerUserId()))
                .sorted((a, b) -> Long.compare(nz(b.getId()), nz(a.getId())))
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public BookingResponse get(String authorization, Long id) {
        return toResponse(ownedJob(authorization, id));
    }

    /** Customer-initiated cancel. Notifies the assigned technician, if any. */
    public BookingResponse cancel(String authorization, Long id) {
        Job job = ownedJob(authorization, id);
        if (!CANCELLABLE.contains(nz(job.getStatus()).toUpperCase(Locale.ROOT))) {
            throw new IllegalArgumentException("This booking can no longer be cancelled");
        }
        Long technicianId = job.getTechnicianId();
        job.setStatus("CANCELLED");
        Job saved = jobRepository.save(job);

        if (technicianId != null) {
            technicianRepository.findById(technicianId).ifPresent(t -> {
                Users techUser = t.getUsers();
                notifications.jobCancelledByCustomer(techUser == null ? null : techUser.getUserId(), saved);
            });
        }
        return toResponse(saved);
    }

    // --- Quotes --------------------------------------------------------------

    /** All quote versions for this booking, latest first - the customer sees
     *  the full negotiation history, not just the current one. */
    @Transactional(readOnly = true)
    public List<ServiceQuoteResponse> listQuotes(String authorization, Long jobId) {
        ownedJob(authorization, jobId); // 404s if not this customer's booking
        return serviceQuoteRepository.findByJobIdOrderByVersionDesc(jobId).stream()
                .map(BookingService::toQuoteDto)
                .collect(Collectors.toList());
    }

    /** Customer accepts the current PENDING quote - the job can now proceed. */
    public BookingResponse acceptQuote(String authorization, Long jobId, Long quoteId) {
        Job job = ownedJob(authorization, jobId);
        ServiceQuote quote = ownedQuote(job, quoteId);
        if (!QUOTE_PENDING.equals(quote.getStatus())) {
            throw new IllegalArgumentException("Only a pending quote can be accepted");
        }
        quote.setStatus(QUOTE_ACCEPTED);
        serviceQuoteRepository.save(quote);

        job.setStatus(STATUS_IN_PROGRESS);
        Job saved = jobRepository.save(job);

        technicianRepository.findById(quote.getTechnicianId()).ifPresent(t -> {
            Users techUser = t.getUsers();
            notifications.quoteAcceptedForTechnician(
                    techUser == null ? null : techUser.getUserId(), saved, quote.getTotalAmount());
        });
        return toResponse(saved);
    }

    /** Customer rejects the current PENDING quote - job goes back to ARRIVED so
     *  the technician can send a revised one, or the customer can cancel outright. */
    public BookingResponse rejectQuote(String authorization, Long jobId, Long quoteId) {
        Job job = ownedJob(authorization, jobId);
        ServiceQuote quote = ownedQuote(job, quoteId);
        if (!QUOTE_PENDING.equals(quote.getStatus())) {
            throw new IllegalArgumentException("Only a pending quote can be rejected");
        }
        quote.setStatus(QUOTE_REJECTED);
        serviceQuoteRepository.save(quote);

        job.setStatus(STATUS_ARRIVED);
        Job saved = jobRepository.save(job);

        technicianRepository.findById(quote.getTechnicianId()).ifPresent(t -> {
            Users techUser = t.getUsers();
            notifications.quoteRejectedForTechnician(
                    techUser == null ? null : techUser.getUserId(), saved);
        });
        return toResponse(saved);
    }

    private ServiceQuote ownedQuote(Job job, Long quoteId) {
        ServiceQuote quote = serviceQuoteRepository.findById(quoteId)
                .orElseThrow(() -> new NoSuchElementException("Quote not found: " + quoteId));
        if (!job.getId().equals(quote.getJobId())) {
            throw new NoSuchElementException("Quote not found: " + quoteId);
        }
        return quote;
    }

    static ServiceQuoteResponse toQuoteDto(ServiceQuote q) {
        ServiceQuoteResponse r = new ServiceQuoteResponse();
        r.setId(q.getId());
        r.setJobId(q.getJobId());
        r.setTechnicianId(q.getTechnicianId());
        r.setVersion(q.getVersion());
        r.setInspectionFee(q.getInspectionFee());
        r.setLaborCost(q.getLaborCost());
        r.setPartsCost(q.getPartsCost());
        r.setTravelFee(q.getTravelFee());
        r.setTotalAmount(q.getTotalAmount());
        r.setReason(q.getReason());
        r.setStatus(q.getStatus());
        r.setCreatedAt(q.getCreatedAt() == null ? null : q.getCreatedAt().toString());
        r.setUpdatedAt(q.getUpdatedAt() == null ? null : q.getUpdatedAt().toString());
        return r;
    }

    // --- helpers ------------------------------------------------------------

    private Job ownedJob(String authorization, Long id) {
        Users me = authSupport.currentUser(authorization);
        Job job = jobRepository.findById(id)
                .orElseThrow(() -> new NoSuchElementException("Booking not found: " + id));
        if (!me.getUserId().equals(job.getCustomerUserId())) {
            // Don't distinguish "not yours" from "doesn't exist".
            throw new NoSuchElementException("Booking not found: " + id);
        }
        return job;
    }

    private Technician resolveAssignee(Long technicianId) {
        if (technicianId == null) {
            return null;
        }
        Technician t = technicianRepository.findById(technicianId).orElse(null);
        if (t == null) {
            return null;
        }
        boolean approved = AP_APPROVED.equalsIgnoreCase(
                t.getApprovalStatus() == null
                        ? (t.isVerified() ? AP_APPROVED : "")
                        : t.getApprovalStatus());
        boolean active = t.getUsers() == null
                || !"SUSPENDED".equalsIgnoreCase(nz(t.getUsers().getStatus()));
        return approved && active ? t : null;
    }

    private BookingResponse toResponse(Job job) {
        if (job.getTechnicianId() == null) {
            return BookingResponse.of(job, null, null, null, null, null);
        }
        return technicianRepository.findById(job.getTechnicianId())
                .map(t -> {
                    String name = technicianName(t);
                    String phone = t.getUsers() == null ? null : t.getUsers().getPhoneNumber();
                    return liveLocationRepository.findByTechnicianId(t.getTechnicianId())
                            .map(loc -> BookingResponse.of(job, name, phone,
                                    loc.getLatitude(), loc.getLongitude(),
                                    loc.getLastUpdate() == null ? null : loc.getLastUpdate().toString()))
                            .orElseGet(() -> BookingResponse.of(job, name, phone, null, null, null));
                })
                .orElseGet(() -> BookingResponse.of(job, null, null, null, null, null));
    }

    private static String technicianName(Technician t) {
        Users u = t.getUsers();
        if (u == null) {
            return t.getBusinessName();
        }
        String n = (nz(u.getFirstName()) + " " + nz(u.getLastName())).trim();
        return n.isEmpty() ? t.getBusinessName() : n;
    }

    private static String buildDescription(BookingRequest req) {
        StringBuilder sb = new StringBuilder();
        sb.append(isBlank(req.getService()) ? req.getCategory().trim() : req.getService().trim());
        sb.append(" - booked via app");
        if (!isBlank(req.getProviderName())) {
            sb.append(" (customer picked ").append(req.getProviderName().trim()).append(")");
        }
        if (!isBlank(req.getNote())) {
            sb.append(". Note: ").append(req.getNote().trim());
        }
        return sb.toString();
    }

    private static String displayName(Users u) {
        String n = (nz(u.getFirstName()) + " " + nz(u.getLastName())).trim();
        if (n.isEmpty() || "-".equals(n)) {
            return nz(u.getEmail());
        }
        return n;
    }

    private static String normalizeBookingType(String raw) {
        return TYPE_SCHEDULED.equalsIgnoreCase(nz(raw).trim()) ? TYPE_SCHEDULED : TYPE_IMMEDIATE;
    }

    private static LocalDateTime parseInstant(String raw) {
        if (raw == null || raw.isBlank()) {
            return null;
        }
        String s = raw.trim();
        try {
            return OffsetDateTime.parse(s).atZoneSameInstant(ZoneId.systemDefault()).toLocalDateTime();
        } catch (RuntimeException ignored) {
            // fall through
        }
        try {
            return Instant.parse(s).atZone(ZoneId.systemDefault()).toLocalDateTime();
        } catch (RuntimeException ignored) {
            // fall through
        }
        try {
            return LocalDateTime.parse(s);
        } catch (RuntimeException ignored) {
            throw new IllegalArgumentException("scheduledAt must be an ISO-8601 date-time");
        }
    }

    private static boolean isBlank(String v) {
        return v == null || v.isBlank();
    }

    private static String blankToNull(String v) {
        return (v == null || v.isBlank()) ? null : v.trim();
    }

    private static String nz(String v) {
        return v == null ? "" : v;
    }

    private static long nz(Long v) {
        return v == null ? 0L : v;
    }
}
