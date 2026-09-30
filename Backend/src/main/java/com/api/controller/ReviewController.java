package com.api.controller;

import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.api.service.ReviewService;
import com.api.dto.booking.ReviewResponse;

/** Public read of a technician's reviews (for their provider profile page). */
@RestController
@RequestMapping("/api/technicians")
public class ReviewController {

    private final ReviewService reviewService;

    public ReviewController(ReviewService reviewService) {
        this.reviewService = reviewService;
    }

    @GetMapping("/{id}/reviews")
    public List<ReviewResponse> forTechnician(@PathVariable Long id) {
        return reviewService.forTechnician(id);
    }
}
