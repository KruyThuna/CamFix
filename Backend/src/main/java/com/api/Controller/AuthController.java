package com.api.Controller;

import java.util.List;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.api.Entity.Users;
import com.api.Service.AuthService;
import com.api.dto.Auth.AuthResponse;
import com.api.dto.Auth.EmailOtpRequest;
import com.api.dto.Auth.EmailVerifyRequest;
import com.api.dto.Auth.GoogleLoginRequest;
import com.api.dto.Auth.LoginRequest;
import com.api.dto.Auth.PhoneOtpRequest;
import com.api.dto.Auth.PhoneVerifyRequest;
import com.api.dto.Auth.RegisterRequest;
import com.api.dto.Auth.UpdateProfileRequest;
import com.api.dto.Auth.UserResponse;

@RestController
@RequestMapping("/api/auth")
@CrossOrigin(origins = "http://localhost:5173")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    // --- Email + password ---------------------------------------------------

    @PostMapping("/register")
    public ResponseEntity<AuthResponse> register(@RequestBody RegisterRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(authService.register(request));
    }

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@RequestBody LoginRequest request) {
        return ResponseEntity.ok(authService.login(request));
    }

    // --- Google -----------------------------------------------------------

    @PostMapping("/google")
    public ResponseEntity<AuthResponse> google(@RequestBody GoogleLoginRequest request) {
        return ResponseEntity.ok(authService.loginWithGoogle(request));
    }

    // --- Phone + OTP ----------------------------------------------------------

    @PostMapping("/phone/request-otp")
    public ResponseEntity<Map<String, Object>> requestOtp(@RequestBody PhoneOtpRequest request) {
        return ResponseEntity.ok(authService.requestPhoneOtp(request));
    }

    @PostMapping("/phone/verify-otp")
    public ResponseEntity<AuthResponse> verifyOtp(@RequestBody PhoneVerifyRequest request) {
        return ResponseEntity.ok(authService.verifyPhoneOtp(request));
    }

    // --- Email + OTP -----------------------------------------------------------

    @PostMapping("/email/request-otp")
    public ResponseEntity<Map<String, Object>> requestEmailOtp(
            @RequestBody EmailOtpRequest request) {
        return ResponseEntity.ok(authService.requestEmailOtp(request));
    }

    @PostMapping("/email/verify-otp")
    public ResponseEntity<AuthResponse> verifyEmailOtp(
            @RequestBody EmailVerifyRequest request) {
        return ResponseEntity.ok(authService.verifyEmailOtp(request));
    }

    // --- Current user -------------------------------------------------------

    @GetMapping("/me")
    public ResponseEntity<UserResponse> me(
            @RequestHeader(value = "Authorization", required = false) String authorization) {
        return ResponseEntity.ok(authService.currentUser(bearer(authorization)));
    }

    @PutMapping("/me")
    public ResponseEntity<UserResponse> updateMe(
            @RequestHeader(value = "Authorization", required = false) String authorization,
            @RequestBody UpdateProfileRequest request) {
        return ResponseEntity.ok(authService.updateCurrentUser(bearer(authorization), request));
    }

    private static String bearer(String header) {
        if (header == null) {
            return null;
        }
        return header.regionMatches(true, 0, "Bearer ", 0, 7)
                ? header.substring(7).trim()
                : header.trim();
    }

    // --- Debug --------------------------------------------------------------

    @GetMapping("/users")
    public ResponseEntity<List<Users>> getAllUsers() {
        return ResponseEntity.ok(authService.findAllUsers());
    }
}
