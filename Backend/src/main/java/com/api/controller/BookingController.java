package com.api.controller;

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

import com.api.service.BookingService;
import com.api.service.KhqrService;
import com.api.service.ReviewService;
import com.api.dto.booking.BookingRequest;
import com.api.dto.booking.BookingResponse;
import com.api.dto.booking.MySpendResponse;
import com.api.dto.booking.PayQuoteRequest;
import com.api.dto.booking.PaymentResponse;
import com.api.dto.booking.QuoteItemDtos;
import com.api.dto.booking.ReviewResponse;
import com.api.dto.booking.ServiceQuoteResponse;
import com.api.dto.booking.SubmitReviewRequest;

/** Customer bookings. Each booking becomes a {@code job} the admin console can see. */
@RestController
@RequestMapping("/api/bookings")
public class BookingController {

    private static final String AUTH = "Authorization";

    private final BookingService bookingService;
    private final ReviewService reviewService;
    private final KhqrService khqrService;

    public BookingController(BookingService bookingService, ReviewService reviewService,
            KhqrService khqrService) {
        this.bookingService = bookingService;
        this.reviewService = reviewService;
        this.khqrService = khqrService;
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

    /** Real sum across every payment the signed-in customer has made - see
     *  {@link BookingService#myTotalSpend}. */
    @GetMapping("/payments/mine")
    public MySpendResponse myTotalSpend(@RequestHeader(value = AUTH, required = false) String auth) {
        return bookingService.myTotalSpend(auth);
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
            @PathVariable Long id, @PathVariable Long quoteId,
            @RequestBody(required = false) QuoteItemDtos.AcceptQuoteRequest body) {
        return bookingService.acceptQuote(auth, id, quoteId,
                body == null ? null : body.approvedItemIds());
    }

    @PostMapping("/{id}/quotes/{quoteId}/reject")
    public BookingResponse rejectQuote(
            @RequestHeader(value = AUTH, required = false) String auth,
            @PathVariable Long id, @PathVariable Long quoteId) {
        return bookingService.rejectQuote(auth, id, quoteId);
    }

    /** Mock payment for an already-accepted quote - see {@link BookingService#payQuote}. */
    @PostMapping("/{id}/quotes/{quoteId}/pay")
    public PaymentResponse payQuote(
            @RequestHeader(value = AUTH, required = false) String auth,
            @PathVariable Long id, @PathVariable Long quoteId,
            @RequestBody PayQuoteRequest body) {
        return bookingService.payQuote(auth, id, quoteId, body);
    }

    /** Leave a star rating for this (completed) booking's technician. */
    @PostMapping("/{id}/review")
    public ResponseEntity<ReviewResponse> submitReview(
            @RequestHeader(value = AUTH, required = false) String auth,
            @PathVariable Long id, @RequestBody SubmitReviewRequest body) {
        return ResponseEntity.status(HttpStatus.CREATED).body(reviewService.submit(auth, id, body));
    }

    /** Whether KHQR (Bakong) is configured on this server. */
    @GetMapping("/khqr/config")
    public KhqrService.KhqrConfig khqrConfig() {
        return khqrService.config();
    }

    /** Generate a KHQR for this accepted quote's total. */
    @PostMapping("/{id}/quotes/{quoteId}/khqr")
    public KhqrService.KhqrResponse startKhqr(
            @RequestHeader(value = AUTH, required = false) String auth,
            @PathVariable Long id, @PathVariable Long quoteId) {
        return bookingService.startKhqr(auth, id, quoteId);
    }

    /** Poll a KHQR: PENDING / PAID (+ payment) / EXPIRED. */
    @GetMapping("/{id}/khqr/{md5}")
    public KhqrService.KhqrStatusResponse khqrStatus(
            @RequestHeader(value = AUTH, required = false) String auth,
            @PathVariable Long id, @PathVariable String md5) {
        return bookingService.khqrStatus(auth, id, md5);
    }

    /** The recorded payment for this booking (for its receipt), or 204 if unpaid. */
    @GetMapping("/{id}/payment")
    public ResponseEntity<PaymentResponse> payment(
            @RequestHeader(value = AUTH, required = false) String auth,
            @PathVariable Long id) {
        PaymentResponse payment = bookingService.paymentFor(auth, id);
        return payment == null ? ResponseEntity.noContent().build() : ResponseEntity.ok(payment);
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
