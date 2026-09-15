package com.api.Controller;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.api.Service.BookingService;
import com.api.Service.ReviewService;
import com.api.dto.Booking.BookingRequest;
import com.api.dto.Booking.BookingResponse;
import com.api.dto.Booking.ReviewResponse;
import com.api.dto.Booking.ServiceQuoteResponse;
import com.api.dto.Booking.SubmitReviewRequest;

/** Customer bookings. Each booking becomes a {@code job} the admin console can see. */
@RestController
@RequestMapping("/api/bookings")
public class BookingController {

    private static final String AUTH = "Authorization";

    private final BookingService bookingService;
    private final ReviewService reviewService;

    public BookingController(BookingService bookingService, ReviewService reviewService) {
        this.bookingService = bookingService;
        this.reviewService = reviewService;
    }

    @PostMapping
    public ResponseEntity<BookingResponse> create(
            @RequestHeader(value = AUTH, required = false) String auth,
            @RequestBody BookingRequest body) {
        return ResponseEntity.status(HttpStatus.CREATED).body(bookingService.create(auth, body));
    }

    @GetMapping("/mine")
    public List<BookingResponse> mine(@RequestHeader(value = AUTH, required = false) String auth) {
        return bookingService.mine(auth);
    }

    @GetMapping("/{id}")
    public BookingResponse get(
            @RequestHeader(value = AUTH, required = false) String auth,
            @PathVariable Long id) {
        return bookingService.get(auth, id);
    }

    @PostMapping("/{id}/cancel")
    public BookingResponse cancel(
            @RequestHeader(value = AUTH, required = false) String auth,
            @PathVariable Long id) {
        return bookingService.cancel(auth, id);
    }

    @GetMapping("/{id}/quotes")
    public List<ServiceQuoteResponse> quotes(
            @RequestHeader(value = AUTH, required = false) String auth,
            @PathVariable Long id) {
        return bookingService.listQuotes(auth, id);
    }

    @PostMapping("/{id}/quotes/{quoteId}/accept")
    public BookingResponse acceptQuote(
            @RequestHeader(value = AUTH, required = false) String auth,
            @PathVariable Long id, @PathVariable Long quoteId) {
        return bookingService.acceptQuote(auth, id, quoteId);
    }

    @PostMapping("/{id}/quotes/{quoteId}/reject")
    public BookingResponse rejectQuote(
            @RequestHeader(value = AUTH, required = false) String auth,
            @PathVariable Long id, @PathVariable Long quoteId) {
        return bookingService.rejectQuote(auth, id, quoteId);
    }

    /** Leave a star rating for this (completed) booking's technician. */
    @PostMapping("/{id}/review")
    public ResponseEntity<ReviewResponse> submitReview(
            @RequestHeader(value = AUTH, required = false) String auth,
            @PathVariable Long id, @RequestBody SubmitReviewRequest body) {
        return ResponseEntity.status(HttpStatus.CREATED).body(reviewService.submit(auth, id, body));
    }

    /** The customer's own review for this booking, or 204 if not reviewed yet. */
    @GetMapping("/{id}/review")
    public ResponseEntity<ReviewResponse> myReview(
            @RequestHeader(value = AUTH, required = false) String auth,
            @PathVariable Long id) {
        ReviewResponse review = reviewService.mine(auth, id);
        return review == null ? ResponseEntity.noContent().build() : ResponseEntity.ok(review);
    }
}
