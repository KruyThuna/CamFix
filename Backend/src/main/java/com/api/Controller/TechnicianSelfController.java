package com.api.Controller;

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

import com.api.Entity.Technician;
import com.api.Service.TechnicianSelfService;
import com.api.Service.TechnicianServiceManager;
import com.api.dto.Auth.AuthResponse;
import com.api.dto.Auth.PhoneOtpRequest;
import com.api.dto.Booking.ServiceQuoteResponse;
import com.api.dto.Booking.SubmitQuoteRequest;
import com.api.dto.Response.CallHistoryResponse;
import com.api.dto.Technician.TechJobResponse;
import com.api.dto.Technician.TechnicianProfileResponse;
import com.api.dto.Technician.TechnicianRegisterRequest;
import com.api.dto.Technician.TechnicianServiceRequest;
import com.api.dto.Technician.TechnicianServiceResponse;

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
    private final TechnicianServiceManager services;

    public TechnicianSelfController(TechnicianSelfService service, TechnicianServiceManager services) {
        this.service = service;
        this.services = services;
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

    @PostMapping("/me/banner")
    public TechnicianProfileResponse uploadBanner(
            @RequestHeader(value = AUTH, required = false) String auth,
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "title", required = false) String title) {
        return service.uploadBanner(auth, file, title);
    }

    @DeleteMapping("/me/banner")
    public TechnicianProfileResponse deleteBanner(
            @RequestHeader(value = AUTH, required = false) String auth) {
        return service.deleteBanner(auth);
    }

    /** Public (no auth) - shown in the customer app's home carousel. */
    @GetMapping("/{id}/banner")
    public ResponseEntity<byte[]> banner(@PathVariable Long id) {
        Technician t = service.bannerOwner(id);
        MediaType type;
        try {
            type = MediaType.parseMediaType(t.getBannerContentType());
        } catch (Exception e) {
            type = MediaType.IMAGE_JPEG;
        }
        return ResponseEntity.ok()
                .contentType(type)
                .header(HttpHeaders.CACHE_CONTROL, "public, max-age=300")
                .body(t.getBanner());
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

    // --- Own named/priced service listings ------------------------------------

    @GetMapping("/me/services")
    public List<TechnicianServiceResponse> myServices(
            @RequestHeader(value = AUTH, required = false) String auth) {
        return services.listMine(auth);
    }

    @PostMapping("/me/services")
    public TechnicianServiceResponse createService(
            @RequestHeader(value = AUTH, required = false) String auth,
            @RequestBody TechnicianServiceRequest body) {
        return services.create(auth, body);
    }

    @PutMapping("/me/services/{id}")
    public TechnicianServiceResponse updateService(
            @RequestHeader(value = AUTH, required = false) String auth,
            @PathVariable Long id,
            @RequestBody TechnicianServiceRequest body) {
        return services.update(auth, id, body);
    }

    @DeleteMapping("/me/services/{id}")
    public void deleteService(
            @RequestHeader(value = AUTH, required = false) String auth,
            @PathVariable Long id) {
        services.delete(auth, id);
    }

    /** Attach / replace the photo on one of the technician's own listings. */
    @PostMapping("/me/services/{id}/photo")
    public TechnicianServiceResponse uploadServicePhoto(
            @RequestHeader(value = AUTH, required = false) String auth,
            @PathVariable Long id,
            @RequestParam("file") MultipartFile file) {
        return services.uploadPhoto(auth, id, file);
    }

    @DeleteMapping("/me/services/{id}/photo")
    public TechnicianServiceResponse deleteServicePhoto(
            @RequestHeader(value = AUTH, required = false) String auth,
            @PathVariable Long id) {
        return services.deletePhoto(auth, id);
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
