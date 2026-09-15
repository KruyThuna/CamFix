package com.api.Service;

import java.time.LocalDateTime;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.api.Entity.Job;
import com.api.Entity.Notification;
import com.api.Entity.Users;
import com.api.Repo.NotificationRepository;
import com.api.Repo.UserRepository;

/**
 * Writes in-app {@link Notification} rows. Every notification is stored in both
 * English and Khmer; the apps render whichever matches the user's chosen
 * language (Khmer falls back to English when a {@code *Km} field is null).
 *
 * <p>Runs in the caller's transaction - a booking / assignment / status change
 * and the notifications it triggers commit together.
 */
@Service
public class NotificationDispatcher {

    public static final String BOOKING_REQUESTED = "BOOKING_REQUESTED";
    public static final String JOB_ASSIGNED = "JOB_ASSIGNED";
    public static final String JOB_ON_THE_WAY = "JOB_ON_THE_WAY";
    public static final String JOB_ARRIVED = "JOB_ARRIVED";
    public static final String JOB_IN_PROGRESS = "JOB_IN_PROGRESS";
    public static final String JOB_COMPLETED = "JOB_COMPLETED";
    public static final String JOB_CANCELLED = "JOB_CANCELLED";
    public static final String JOB_DECLINED = "JOB_DECLINED";
    public static final String JOB_CANCELLED_BY_CUSTOMER = "JOB_CANCELLED_BY_CUSTOMER";
    public static final String QUOTE_SUBMITTED = "QUOTE_SUBMITTED";
    public static final String QUOTE_ACCEPTED = "QUOTE_ACCEPTED";
    public static final String QUOTE_REJECTED = "QUOTE_REJECTED";
    public static final String REVIEW_SUBMITTED = "REVIEW_SUBMITTED";

    private final NotificationRepository notificationRepository;
    private final UserRepository userRepository;

    public NotificationDispatcher(NotificationRepository notificationRepository,
            UserRepository userRepository) {
        this.notificationRepository = notificationRepository;
        this.userRepository = userRepository;
    }

    // --- Low level ---------------------------------------------------------

    @Transactional
    public void push(Long userId, String type, Long jobId,
            String titleEn, String bodyEn, String titleKm, String bodyKm) {
        if (userId == null) {
            return;
        }
        Users user = userRepository.findById(userId).orElse(null);
        if (user == null) {
            return;
        }
        Notification n = new Notification();
        n.setUser(user);
        n.setType(type);
        n.setJobId(jobId);
        n.setTitle(titleEn);
        n.setMessage(bodyEn);
        n.setTitleKm(titleKm);
        n.setMessageKm(bodyKm);
        n.setRead(false);
        n.setCreatedAt(LocalDateTime.now());
        notificationRepository.save(n);
    }

    // --- Templates -------------------------------------------------------------

    /** Customer just placed a booking (job is REQUESTED / unassigned). */
    public void bookingRequested(Long customerUserId, Job job) {
        String cat = nz(job.getCategory());
        String catKm = kmCategory(cat);
        push(customerUserId, BOOKING_REQUESTED, job.getId(),
                "Booking requested",
                "Your " + cat + " booking has been received. "
                        + "We'll let you know as soon as a technician is assigned.",
                "បានស្នើសុំការកក់",
                "ការកក់សេវាកម្ម " + catKm + " របស់អ្នកត្រូវបានទទួល។ "
                        + "យើងនឹងជូនដំណឹងភ្លាមៗនៅពេលមានជាងទទួលការងារ។");
    }

    /** A technician has been put on the job. */
    public void jobAssignedToTechnician(Long technicianUserId, Job job) {
        String tail = job.getAddress() == null || job.getAddress().isBlank()
                ? "" : " · " + job.getAddress();
        push(technicianUserId, JOB_ASSIGNED, job.getId(),
                "New job assigned",
                nz(job.getCustomerName()) + " · " + nz(job.getCategory()) + tail
                        + ". Open the app to accept and start.",
                "ការងារថ្មីត្រូវបានចាត់តាំង",
                nz(job.getCustomerName()) + " · " + kmCategory(nz(job.getCategory())) + tail
                        + "។ បើកកម្មវិធីដើម្បីទទួល និងចាប់ផ្តើម។");
    }

    /** Tell the customer their job moved to {@code status}. */
    public void jobUpdateForCustomer(Job job, String status, String technicianName) {
        Long uid = job.getCustomerUserId();
        if (uid == null) {
            return;
        }
        String cat = nz(job.getCategory());
        String catKm = kmCategory(cat);
        String who = technicianName == null || technicianName.isBlank() ? "A technician" : technicianName;
        String whoKm = technicianName == null || technicianName.isBlank() ? "ជាងម្នាក់" : technicianName;
        switch (status) {
            case "ASSIGNED" -> push(uid, JOB_ASSIGNED, job.getId(),
                    "Technician assigned",
                    who + " has been assigned to your " + cat + " booking.",
                    "បានចាត់តាំងជាង",
                    whoKm + " ត្រូវបានចាត់តាំងសម្រាប់ការកក់ " + catKm + " របស់អ្នក។");
            case "ON_THE_WAY" -> push(uid, JOB_ON_THE_WAY, job.getId(),
                    "Your technician is on the way",
                    who + " is on the way for your " + cat + " booking.",
                    "ជាងកំពុងធ្វើដំណើរមក",
                    whoKm + " កំពុងធ្វើដំណើរមកសម្រាប់ការកក់ " + catKm + " របស់អ្នក។");
            case "ARRIVED" -> push(uid, JOB_ARRIVED, job.getId(),
                    "Your technician has arrived",
                    who + " has arrived at your location.",
                    "ជាងបានមកដល់",
                    whoKm + " បានមកដល់ទីតាំងរបស់អ្នកហើយ។");
            case "IN_PROGRESS" -> push(uid, JOB_IN_PROGRESS, job.getId(),
                    "Your technician has started",
                    who + " has started work on your " + cat + " job.",
                    "ជាងបានចាប់ផ្តើមការងារ",
                    whoKm + " បានចាប់ផ្តើមការងារ " + catKm + " របស់អ្នក។");
            case "COMPLETED" -> push(uid, JOB_COMPLETED, job.getId(),
                    "Job completed",
                    "Your " + cat + " job is marked complete. Thanks for using CAM FIX!",
                    "ការងារបានបញ្ចប់",
                    "ការងារ " + catKm + " របស់អ្នកត្រូវបានសម្គាល់ថាបានបញ្ចប់។ សូមអរគុណដែលបានប្រើ CAM FIX!");
            case "CANCELLED" -> push(uid, JOB_CANCELLED, job.getId(),
                    "Booking cancelled",
                    "Your " + cat + " booking has been cancelled.",
                    "ការកក់ត្រូវបានលុបចោល",
                    "ការកក់ " + catKm + " របស់អ្នកត្រូវបានលុបចោល។");
            case "REQUESTED" -> push(uid, JOB_DECLINED, job.getId(),
                    "Finding another technician",
                    "We're reassigning your " + cat + " booking to another technician.",
                    "កំពុងស្វែងរកជាងផ្សេង",
                    "យើងកំពុងប្តូរការកក់ " + catKm + " របស់អ្នកទៅជាងផ្សេងទៀត។");
            default -> {
                /* no customer-facing message for other states */
            }
        }
    }

    /** The customer cancelled a job that had a technician assigned - tell the
     *  technician, and that a cancellation fee applied to the customer (every
     *  cancellable state charges something now - see Camfix_App's
     *  {@code CancellationFee} - so this is always true, not conditional). */
    public void jobCancelledByCustomer(Long technicianUserId, Job job) {
        if (technicianUserId == null) {
            return;
        }
        String cat = nz(job.getCategory());
        push(technicianUserId, JOB_CANCELLED_BY_CUSTOMER, job.getId(),
                "Job cancelled",
                nz(job.getCustomerName()) + " cancelled the " + cat
                        + " job - a cancellation fee applies to them. It's off your list.",
                "ការងារត្រូវបានលុបចោល",
                nz(job.getCustomerName()) + " បានលុបចោលការងារ " + kmCategory(cat)
                        + " - ថ្លៃសេវាលុបចោលអនុវត្តចំពោះគាត់។ វាត្រូវបានដកចេញពីបញ្ជីរបស់អ្នក។");
    }

    /** Technician submitted (or revised) a quote - tell the customer, with the amount. */
    public void quoteSubmittedForCustomer(Job job, double totalAmount, boolean isRevision) {
        Long uid = job.getCustomerUserId();
        if (uid == null) {
            return;
        }
        String cat = nz(job.getCategory());
        String amount = String.format("$%.2f", totalAmount);
        String verbEn = isRevision ? "sent a revised quote" : "sent a quote";
        String verbKm = isRevision ? "បានផ្ញើសម្រង់ថ្លៃដែលបានកែសម្រួល" : "បានផ្ញើសម្រង់ថ្លៃ";
        push(uid, QUOTE_SUBMITTED, job.getId(),
                isRevision ? "Revised quote received" : "Quote received",
                "Your technician " + verbEn + " of " + amount + " for your " + cat + " job. Open the app to review it.",
                isRevision ? "បានទទួលសម្រង់ថ្លៃដែលបានកែសម្រួល" : "បានទទួលសម្រង់ថ្លៃ",
                "ជាងរបស់អ្នក " + verbKm + " ចំនួន " + amount + " សម្រាប់ការងារ " + kmCategory(cat) + "។ បើកកម្មវិធីដើម្បីពិនិត្យមើល។");
    }

    /** Customer accepted a quote - tell the technician the job can proceed. */
    public void quoteAcceptedForTechnician(Long technicianUserId, Job job, double totalAmount) {
        if (technicianUserId == null) {
            return;
        }
        String cat = nz(job.getCategory());
        String amount = String.format("$%.2f", totalAmount);
        push(technicianUserId, QUOTE_ACCEPTED, job.getId(),
                "Quote accepted",
                nz(job.getCustomerName()) + " accepted your " + amount + " quote for the " + cat + " job. You can start work.",
                "សម្រង់ថ្លៃត្រូវបានទទួលយក",
                nz(job.getCustomerName()) + " បានទទួលយកសម្រង់ថ្លៃ " + amount + " សម្រាប់ការងារ " + kmCategory(cat) + "។ អ្នកអាចចាប់ផ្តើមការងារបាន។");
    }

    /** Customer rejected a quote - tell the technician so they can revise it. */
    public void quoteRejectedForTechnician(Long technicianUserId, Job job) {
        if (technicianUserId == null) {
            return;
        }
        String cat = nz(job.getCategory());
        push(technicianUserId, QUOTE_REJECTED, job.getId(),
                "Quote declined",
                nz(job.getCustomerName()) + " declined your quote for the " + cat + " job. You can send a revised quote.",
                "សម្រង់ថ្លៃត្រូវបានបដិសេធ",
                nz(job.getCustomerName()) + " បានបដិសេធសម្រង់ថ្លៃសម្រាប់ការងារ " + kmCategory(cat) + "។ អ្នកអាចផ្ញើសម្រង់ថ្លៃថ្មីបាន។");
    }

    /** Customer left a star rating (+ optional comment) for a completed job. */
    public void reviewSubmittedForTechnician(Long technicianUserId, Job job, int rating) {
        if (technicianUserId == null) {
            return;
        }
        String cat = nz(job.getCategory());
        String stars = rating + "/5";
        push(technicianUserId, REVIEW_SUBMITTED, job.getId(),
                "New review",
                nz(job.getCustomerName()) + " rated your " + cat + " job " + stars + ".",
                "ការវាយតម្លៃថ្មី",
                nz(job.getCustomerName()) + " បានវាយតម្លៃការងារ " + kmCategory(cat) + " របស់អ្នក " + stars + "។");
    }

    /** English category name -> Khmer, for the {@code *Km} notification copy.
     *  Unknown categories pass through unchanged. */
    private static String kmCategory(String english) {
        return switch (english) {
            case "Air Conditioner" -> "ម៉ាស៊ីនត្រជាក់";
            case "Electrical" -> "អគ្គិសនី";
            case "Appliance Repair" -> "ជួសជុលគ្រឿងប្រើប្រាស់";
            case "Motorcycle" -> "ម៉ូតូ";
            case "Car" -> "ឡាន";
            case "Water network" -> "បណ្តាញទឹក";
            default -> english;
        };
    }

    private static String nz(String v) {
        return v == null ? "" : v;
    }
}
