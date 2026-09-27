package com.api.Service;

import java.security.SecureRandom;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.time.ZoneId;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.NoSuchElementException;
import java.util.Set;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.api.Entity.Job;
import com.api.Entity.Payment;
import com.api.Entity.ServiceQuote;
import com.api.Entity.Technician;
import com.api.Entity.TechnicianServiceListing;
import com.api.Entity.Users;
import com.api.Repo.JobRepository;
import com.api.Repo.PaymentRepository;
import com.api.Repo.ServiceQuoteRepository;
import com.api.Repo.TechnicianLiveLocationRepository;
import com.api.Repo.TechnicianRepository;
import com.api.Repo.TechnicianServiceRepository;
import com.api.Security.AuthSupport;
import com.api.dto.Booking.BookingRequest;
import com.api.dto.Booking.BookingResponse;
import com.api.dto.Booking.MySpendResponse;
import com.api.dto.Booking.PayQuoteRequest;
import com.api.dto.Booking.PaymentResponse;
import com.api.dto.Booking.ServiceQuoteResponse;

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
    private static final String TYPE_SELF_DROP = "SELF_DROP";

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
    private final PaymentRepository paymentRepository;
    private final ServicePriceService servicePriceService;
    private final NotificationDispatcher notifications;
    private final TechnicianServiceRepository technicianServiceRepository;

    private static final SecureRandom RNG = new SecureRandom();

    public BookingService(AuthSupport authSupport,
            JobRepository jobRepository,
            TechnicianRepository technicianRepository,
            TechnicianLiveLocationRepository liveLocationRepository,
            ServiceQuoteRepository serviceQuoteRepository,
            PaymentRepository paymentRepository,
            ServicePriceService servicePriceService,
            NotificationDispatcher notifications,
            TechnicianServiceRepository technicianServiceRepository,
            QuoteItemService quoteItems,
            KhqrService khqr) {
        this.authSupport = authSupport;
        this.jobRepository = jobRepository;
        this.technicianRepository = technicianRepository;
        this.liveLocationRepository = liveLocationRepository;
        this.serviceQuoteRepository = serviceQuoteRepository;
        this.paymentRepository = paymentRepository;
        this.servicePriceService = servicePriceService;
        this.notifications = notifications;
        this.technicianServiceRepository = technicianServiceRepository;
        this.quoteItems = quoteItems;
        this.khqr = khqr;
    }

    private final KhqrService khqr;

    private final QuoteItemService quoteItems;

    public BookingResponse create(String authorization, BookingRequest req) {
        Users me = authSupport.currentUser(authorization);
        if (req == null || isBlank(req.getCategory())) {
            throw new IllegalArgumentException("category is required");
        }

        // A real listing the technician set up themselves, when the customer
        // booked one directly (Achievements tab) rather than a generic category
        // request - its own real price overrides the category's catalog price.
        TechnicianServiceListing listing = req.getTechnicianServiceId() == null
                ? null
                : technicianServiceRepository.findById(req.getTechnicianServiceId()).orElse(null);

        Job job = new Job();
        job.setCustomerUserId(me.getUserId());
        job.setCustomerName(displayName(me));
        job.setCustomerPhone(nz(me.getPhoneNumber()));
        job.setCategory(req.getCategory().trim());
        job.setDescription(buildDescription(req, listing));
        job.setAddress(blankToNull(req.getAddress()));
        job.setLat(req.getLat());
        job.setLng(req.getLng());
        job.setScheduledAt(parseInstant(req.getScheduledAt()));
        job.setNotes(blankToNull(req.getNote()));
        job.setBookingType(normalizeBookingType(req.getBookingType()));
        job.setTechnicianServiceId(listing == null ? null : listing.getId());
        job.setStartingPrice(listing != null && listing.getPrice() != null
                ? listing.getPrice()
                : servicePriceService.startingPriceForCategoryName(job.getCategory()));

        Technician assignee = resolveAssignee(req.getTechnicianId());
        if (TYPE_SELF_DROP.equals(job.getBookingType())) {
            // The drop-off point is the technician's own shop, so there has to be one.
            if (assignee == null) {
                throw new IllegalArgumentException("Self Drop needs an approved technician to drop off with");
            }
            job.setBenchFee(servicePriceService.benchFeeForCategoryName(job.getCategory()));
        }
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

    /** Real sum across every payment the signed-in customer has made, for the
     *  profile screen's "Total Spend" stat - never an invented figure. */
    @Transactional(readOnly = true)
    public MySpendResponse myTotalSpend(String authorization) {
        Users me = authSupport.currentUser(authorization);
        List<Long> myJobIds = jobRepository.findAll().stream()
                .filter(j -> me.getUserId().equals(j.getCustomerUserId()))
                .map(Job::getId)
                .collect(Collectors.toList());
        List<Payment> payments = myJobIds.isEmpty()
                ? List.of()
                : paymentRepository.findByJobIdIn(myJobIds);
        double total = payments.stream()
                .mapToDouble(pmt -> pmt.getTotalAmount() == null ? 0 : pmt.getTotalAmount())
                .sum();
        MySpendResponse r = new MySpendResponse();
        r.setTotalSpend(round2(total));
        r.setPayments(payments.stream()
                .sorted(Comparator.comparing(Payment::getId).reversed())
                .map(BookingService::toPaymentDto)
                .collect(Collectors.toList()));
        return r;
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
                .map(quoteItems::toDto)
                .collect(Collectors.toList());
    }

    /** Customer accepts the current PENDING quote - the job can now proceed. */
    public BookingResponse acceptQuote(String authorization, Long jobId, Long quoteId) {
        return acceptQuote(authorization, jobId, quoteId, null);
    }

    /** Accept with a per-item decision: only [approvedItemIds] are done and
     *  paid for (null = approve every item). */
    public BookingResponse acceptQuote(String authorization, Long jobId, Long quoteId,
            List<Long> approvedItemIds) {
        Job job = ownedJob(authorization, jobId);
        ServiceQuote quote = ownedQuote(job, quoteId);
        if (!QUOTE_PENDING.equals(quote.getStatus())) {
            throw new IllegalArgumentException("Only a pending quote can be accepted");
        }
        quote.setTotalAmount(quoteItems.applyDecision(quote, approvedItemIds));
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

    private static final Set<String> PAYMENT_METHODS = Set.of("APPLE_PAY", "CARD", "PAYPAL");

    /** Mock payment for an accepted quote - no real card processor is wired
     *  up, this just records the charge. Paying again for an already-paid
     *  quote returns the original payment rather than charging twice. */
    public PaymentResponse payQuote(String authorization, Long jobId, Long quoteId, PayQuoteRequest req) {
        Job job = ownedJob(authorization, jobId);
        ServiceQuote quote = ownedQuote(job, quoteId);
        if (!QUOTE_ACCEPTED.equals(quote.getStatus())) {
            throw new IllegalArgumentException("Only an accepted quote can be paid");
        }
        String method = req == null ? null : req.getPaymentMethod();
        if (method == null || !PAYMENT_METHODS.contains(method.toUpperCase(Locale.ROOT))) {
            throw new IllegalArgumentException("paymentMethod must be one of " + PAYMENT_METHODS);
        }
        method = method.toUpperCase(Locale.ROOT);
        String cardLast4 = req.getCardLast4();
        if ("CARD".equals(method)) {
            if (cardLast4 == null || !cardLast4.matches("\\d{4}")) {
                throw new IllegalArgumentException("cardLast4 must be exactly 4 digits for a CARD payment");
            }
        } else {
            cardLast4 = null;
        }

        Payment existing = paymentRepository.findByQuoteId(quoteId).orElse(null);
        if (existing != null) {
            return toPaymentDto(existing);
        }
        return toPaymentDto(recordPayment(job, quote, method, cardLast4));
    }

    /** [base, platformFee, tax, total] for an accepted quote - the single
     *  formula every payment method (incl. KHQR) charges. */
    static double[] charge(ServiceQuote quote) {
        double base = quote.getTotalAmount() == null ? 0 : quote.getTotalAmount();
        // Platform processing fee and tax are flat percentages set by CamFix.
        double platformFee = round2(Math.max(0.99, base * 0.018));
        double tax = round2((base + platformFee) * 0.085);
        double total = round2(base + platformFee + tax);
        return new double[] {base, platformFee, tax, total};
    }

    Payment recordPayment(Job job, ServiceQuote quote, String method, String cardLast4) {
        double[] c = charge(quote);
        Payment payment = new Payment();
        payment.setJobId(job.getId());
        payment.setQuoteId(quote.getId());
        payment.setBaseAmount(c[0]);
        payment.setPlatformFee(c[1]);
        payment.setTaxAmount(c[2]);
        payment.setTotalAmount(c[3]);
        payment.setPaymentMethod(method);
        payment.setCardLast4(cardLast4);
        payment.setServiceRef(generateServiceRef());
        return paymentRepository.save(payment);
    }

    // --- KHQR (Bakong) -------------------------------------------------------

    /** Create a dynamic KHQR for this accepted quote's total. */
    public KhqrService.KhqrResponse startKhqr(String authorization, Long jobId, Long quoteId) {
        Job job = ownedJob(authorization, jobId);
        ServiceQuote quote = ownedQuote(job, quoteId);
        if (!QUOTE_ACCEPTED.equals(quote.getStatus())) {
            throw new IllegalArgumentException("Only an accepted quote can be paid");
        }
        if (paymentRepository.findByQuoteId(quoteId).isPresent()) {
            throw new IllegalArgumentException("This quote is already paid");
        }
        return khqr.create(job.getId(), quote.getId(), charge(quote)[3]);
    }

    /**
     * Poll a KHQR: asks Bakong whether the transfer landed and, once it has
     * (right amount + currency), records the real payment. Returns the
     * status plus the payment when paid.
     */
    public KhqrService.KhqrStatusResponse khqrStatus(String authorization, Long jobId, String md5) {
        Job job = ownedJob(authorization, jobId);
        KhqrService.Check check = khqr.check(job.getId(), md5);
        PaymentResponse paid = null;
        if (check.paid()) {
            ServiceQuote quote = ownedQuote(job, check.quoteId());
            Payment p = paymentRepository.findByQuoteId(quote.getId())
                    .orElseGet(() -> recordPayment(job, quote, "KHQR", null));
            paid = toPaymentDto(p);
        }
        return new KhqrService.KhqrStatusResponse(check.status(), paid);
    }

    /** Latest payment recorded for one of the caller's own jobs, or null if unpaid. */
    public PaymentResponse paymentFor(String authorization, Long jobId) {
        Job job = ownedJob(authorization, jobId);
        return paymentRepository.findFirstByJobIdOrderByIdDesc(job.getId())
                .map(BookingService::toPaymentDto)
                .orElse(null);
    }

    private static double round2(double v) {
        return Math.round(v * 100.0) / 100.0;
    }

    private static String generateServiceRef() {
        String digits = String.format(Locale.ROOT, "%05d", RNG.nextInt(100_000));
        String letters = "" + (char) ('A' + RNG.nextInt(26)) + (char) ('A' + RNG.nextInt(26));
        return "SP-" + digits + "-" + letters;
    }

    private static PaymentResponse toPaymentDto(Payment p) {
        PaymentResponse r = new PaymentResponse();
        r.setJobId(p.getJobId());
        r.setQuoteId(p.getQuoteId());
        r.setBaseAmount(p.getBaseAmount());
        r.setPlatformFee(p.getPlatformFee());
        r.setTaxAmount(p.getTaxAmount());
        r.setTotalAmount(p.getTotalAmount());
        r.setPaymentMethod(p.getPaymentMethod());
        r.setCardLast4(p.getCardLast4());
        r.setServiceRef(p.getServiceRef());
        r.setCreatedAt(p.getCreatedAt() == null ? null : p.getCreatedAt().toString());
        return r;
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

    private static String buildDescription(BookingRequest req, TechnicianServiceListing listing) {
        StringBuilder sb = new StringBuilder();
        if (listing != null && !isBlank(listing.getTitle())) {
            sb.append(listing.getTitle().trim());
        } else {
            sb.append(isBlank(req.getService()) ? req.getCategory().trim() : req.getService().trim());
        }
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
        String v = nz(raw).trim();
        if (TYPE_SELF_DROP.equalsIgnoreCase(v)) {
            return TYPE_SELF_DROP;
        }
        return TYPE_SCHEDULED.equalsIgnoreCase(v) ? TYPE_SCHEDULED : TYPE_IMMEDIATE;
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
