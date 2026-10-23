package com.api.controller;

import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.api.service.ReviewService;
import com.api.dto.booking.ReviewResponse;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;

/** Public read of a technician's reviews (for their provider profile page). */
@Tag(name = "Review CRUD", description = "Technician reviews and customer feedback CRUD operations")
@RestController
@RequestMapping("/api/technicians")
public class ReviewController {

    private final ReviewService reviewService;

    public ReviewController(ReviewService reviewService) {
        this.reviewService = reviewService;
    }

    @Operation(summary = "Get reviews for technician", description = "Read/list all reviews for a technician", tags = {"Read", "Review CRUD"})
    @GetMapping("/{id}/reviews")
    public List<ReviewResponse> forTechnician(@PathVariable Long id) {
        return reviewService.forTechnician(id);
    }
}