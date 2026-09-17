package com.api.controller;

import java.util.List;
import java.util.Map;

import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import com.api.entity.Technician;
import com.api.service.TechnicianSelfService;
import com.api.dto.auth.AuthResponse;
import com.api.dto.auth.PhoneOtpRequest;
import com.api.dto.booking.ServiceQuoteResponse;
import com.api.dto.booking.SubmitQuoteRequest;
import com.api.dto.response.CallHistoryResponse;
import com.api.dto.technician.TechJobResponse;
import com.api.dto.technician.TechnicianProfileResponse;
import com.api.dto.technician.TechnicianRegisterRequest;

/**
 * The technician app's self-service API. Registration is open; everything under
 * {@code /me} needs the bearer token issued at register/login and is resolved
 * in {@link TechnicianSelfService}. Sits alongside the admin-managed
 * {@code TechnicianController} on the same base path (no route overlap).
 */
@RestController
@RequestMapping("/api/technician")
public class TechnicianSelfController {

    private static final String AUTH = "Authorization";

    private final TechnicianSelfService service;

    public TechnicianSelfController(TechnicianSelfService service) {
        this.service = service;
    }

    // --- Registration / auth ------------------------------------------------

    @PostMapping("/auth/phone/request-otp")
    public Map<String, Object> requestPhoneOtp(@RequestBody PhoneOtpRequest body) {
        return service.requestPhoneOtp(body);
    }

    @PostMapping("/auth/register")
    public ResponseEntity<AuthResponse> register(@RequestBody TechnicianRegisterRequest body) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.register(body));
    }

    @PostMapping("/auth/phone/verify-otp")
    public AuthResponse verifyPhoneOtp(@RequestBody VerifyOtpBody body) {
        return service.verifyPhoneOtp(
                body == null ? null : body.phoneNumber(),
                body == null ? null : body.code());
    }

    // --- Profile -----------------------------------------------------------

    @GetMapping("/me")
    public TechnicianProfileResponse me(@RequestHeader(value = AUTH, required = false) String auth) {
        return service.me(auth);
    }

    @PutMapping("/me")
    public TechnicianProfileResponse updateMe(
            @RequestHeader(value = AUTH, required = false) String auth,
            @RequestBody(required = false) Map<String, Object> fields) {
        return service.updateProfile(auth, fields);
    }

    @PatchMapping("/me/availability")
    public TechnicianProfileResponse setAvailability(
            @RequestHeader(value = AUTH, required = false) String auth,
            @RequestBody AvailabilityBody body) {
        return service.setAvailability(auth, body != null && Boolean.TRUE.equals(body.available()));
    }

    @PostMapping("/me/photo")
    public TechnicianProfileResponse uploadPhoto(
            @RequestHeader(value = AUTH, required = false) String auth,
            @RequestParam("file") MultipartFile file) {
        return service.uploadPhoto(auth, file);
    }

    @DeleteMapping("/me/photo")
    public TechnicianProfileResponse deletePhoto(
            @RequestHeader(value = AUTH, required = false) String auth) {
        return service.deletePhoto(auth);
    }

    /** Public (no auth) so any client - technician app, admin console, or a
     *  customer's tracking screen - can render it as a plain image URL. */
    @GetMapping("/{id}/photo")
    public ResponseEntity<byte[]> photo(@PathVariable Long id) {
        Technician t = service.photoOwner(id);
        MediaType type;
        try {
            type = MediaType.parseMediaType(t.getPhotoContentType());
        } catch (Exception e) {
            type = MediaType.IMAGE_JPEG;
        }
        return ResponseEntity.ok()
                .contentType(type)
                .header(HttpHeaders.CACHE_CONTROL, "private, max-age=300")
                .body(t.getPhoto());
    }

    @PatchMapping("/me/location")
    public ResponseEntity<Void> pushLocation(
            @RequestHeader(value = AUTH, required = false) String auth,
            @RequestBody LocationBody body) {
        service.pushLocation(auth, body == null ? null : body.lat(), body == null ? null : body.lng());
        return ResponseEntity.noContent().build();
    }

    // --- Jobs ------------------------------------------------------------------

    @GetMapping("/me/jobs")
    public List<TechJobResponse> myJobs(
            @RequestHeader(value = AUTH, required = false) String auth,
            @RequestParam(required = false) String status) {
        return service.myJobs(auth, status);
    }

    @GetMapping("/me/jobs/{id}")
    public TechJobResponse job(
            @RequestHeader(value = AUTH, required = false) String auth,
            @PathVariable Long id) {
        return service.job(auth, id);
    }

    @PostMapping("/me/jobs/{id}/status")
    public TechJobResponse setJobStatus(
            @RequestHeader(value = AUTH, required = false) String auth,
            @PathVariable Long id,
            @RequestBody(required = false) StatusBody body) {
        return service.setJobStatus(auth, id, body == null ? null : body.status());
    }

    @PostMapping("/me/jobs/{id}/quotes")
    public ServiceQuoteResponse submitQuote(
            @RequestHeader(value = AUTH, required = false) String auth,
            @PathVariable Long id,
            @RequestBody(required = false) SubmitQuoteRequest body) {
        return service.submitQuote(auth, id, body);
    }

    @GetMapping("/me/jobs/{id}/quotes")
    public List<ServiceQuoteResponse> jobQuotes(
            @RequestHeader(value = AUTH, required = false) String auth,
            @PathVariable Long id) {
        return service.jobQuotes(auth, id);
    }

    @GetMapping("/me/calls")
    public List<CallHistoryResponse> myCalls(
            @RequestHeader(value = AUTH, required = false) String auth) {
        return service.myCalls(auth);
    }

    // --- Small request bodies ------------------------------------------------

    public record VerifyOtpBody(String phoneNumber, String code) {
    }

    public record AvailabilityBody(Boolean available) {
    }

    public record LocationBody(Double lat, Double lng) {
    }

    public record StatusBody(String status) {
    }
}
