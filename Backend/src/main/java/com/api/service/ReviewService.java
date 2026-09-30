package com.api.service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;
import java.util.NoSuchElementException;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.api.entity.Job;
import com.api.entity.Review;
import com.api.entity.Technician;
import com.api.entity.Users;
import com.api.repository.JobRepository;
import com.api.repository.ReviewRepository;
import com.api.repository.TechnicianRepository;
import com.api.security.AuthSupport;
import com.api.dto.booking.ReviewResponse;
import com.api.dto.booking.SubmitReviewRequest;

/**
 * Customer ratings for completed jobs. A review can only be left once per job,
 * only by that job's own customer, and only once the job is {@code COMPLETED}.
 * Submitting one recomputes {@code Technician.averageRating}/{@code ratingCount}
 * from the real review rows - those two columns are a cache, never edited
 * directly (the one exception is the admin console's manual override in
 * {@code AdminService}, kept for correcting bad data).
 */
@Service
@Transactional
public class ReviewService {

    private static final String STATUS_COMPLETED = "COMPLETED";

    private final AuthSupport authSupport;
    private final JobRepository jobRepository;
    private final ReviewRepository reviewRepository;
    private final TechnicianRepository technicianRepository;
    private final NotificationDispatcher notifications;

    public ReviewService(AuthSupport authSupport,
            JobRepository jobRepository,
            ReviewRepository reviewRepository,
            TechnicianRepository technicianRepository,
            NotificationDispatcher notifications) {
        this.authSupport = authSupport;
        this.jobRepository = jobRepository;
        this.reviewRepository = reviewRepository;
        this.technicianRepository = technicianRepository;
        this.notifications = notifications;
    }

    public ReviewResponse submit(String authorization, Long jobId, SubmitReviewRequest req) {
        Users me = authSupport.currentUser(authorization);
        Job job = jobRepository.findById(jobId)
                .orElseThrow(() -> new NoSuchElementException("Booking not found: " + jobId));
        if (!me.getUserId().equals(job.getCustomerUserId())) {
            throw new NoSuchElementException("Booking not found: " + jobId);
        }
        if (!STATUS_COMPLETED.equals(job.getStatus())) {
            throw new IllegalArgumentException("Only a completed job can be reviewed");
        }
        if (job.getTechnicianId() == null) {
            throw new IllegalArgumentException("This job has no technician to review");
        }
        if (reviewRepository.existsByJobId(jobId)) {
            throw new IllegalArgumentException("This job has already been reviewed");
        }
        int rating = req == null || req.getRating() == null ? 0 : req.getRating();
        if (rating < 1 || rating > 5) {
            throw new IllegalArgumentException("rating must be between 1 and 5");
        }

        Review review = new Review();
        review.setJobId(jobId);
        review.setCustomerUserId(me.getUserId());
        review.setTechnicianId(job.getTechnicianId());
        review.setRating(rating);
        review.setComment(blankToNull(req.getComment()));
        Review saved = reviewRepository.save(review);

        Technician tech = recomputeTechnicianRating(job.getTechnicianId());
        if (tech != null && tech.getUsers() != null) {
            notifications.reviewSubmittedForTechnician(tech.getUsers().getUserId(), job, rating);
        }

        return toDto(saved, job);
    }

    @Transactional(readOnly = true)
    public ReviewResponse mine(String authorization, Long jobId) {
        Users me = authSupport.currentUser(authorization);
        Job job = jobRepository.findById(jobId)
                .orElseThrow(() -> new NoSuchElementException("Booking not found: " + jobId));
        if (!me.getUserId().equals(job.getCustomerUserId())) {
            throw new NoSuchElementException("Booking not found: " + jobId);
        }
        return reviewRepository.findByJobId(jobId)
                .map(r -> toDto(r, job))
                .orElse(null);
    }

    @Transactional(readOnly = true)
    public List<ReviewResponse> forTechnician(Long technicianId) {
        return reviewRepository.findByTechnicianIdOrderByCreatedAtDesc(technicianId).stream()
                .map(r -> toDto(r, jobRepository.findById(r.getJobId()).orElse(null)))
                .collect(Collectors.toList());
    }

    private Technician recomputeTechnicianRating(Long technicianId) {
        Technician tech = technicianRepository.findById(technicianId).orElse(null);
        if (tech == null) {
            return null;
        }
        List<Review> reviews = reviewRepository.findByTechnicianIdOrderByCreatedAtDesc(technicianId);
        int count = reviews.size();
        double average = count == 0 ? 0d
                : reviews.stream().mapToInt(Review::getRating).average().orElse(0d);
        tech.setRatingCount(count);
        tech.setAverageRating(BigDecimal.valueOf(average).setScale(2, RoundingMode.HALF_UP));
        return technicianRepository.save(tech);
    }

    private static ReviewResponse toDto(Review r, Job job) {
        ReviewResponse dto = new ReviewResponse();
        dto.setId(r.getId());
        dto.setJobId(r.getJobId());
        dto.setTechnicianId(r.getTechnicianId());
        dto.setCustomerName(job == null ? null : job.getCustomerName());
        dto.setRating(r.getRating());
        dto.setComment(r.getComment());
        dto.setCreatedAt(r.getCreatedAt() == null ? null : r.getCreatedAt().toString());
        return dto;
    }

    private static String blankToNull(String v) {
        return (v == null || v.isBlank()) ? null : v.trim();
    }
}
