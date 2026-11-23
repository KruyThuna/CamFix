package com.api.modules.auth.controller;



import com.api.modules.user.service.UserManagementService;
import com.api.modules.user.entity.Users;
import io.swagger.v3.oas.annotations.tags.Tag;

import java.util.List;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.api.modules.auth.service.AuthService;
import com.api.modules.auth.dto.AuthResponse;
import com.api.modules.auth.dto.EmailOtpRequest;
import com.api.modules.auth.dto.EmailVerifyRequest;
import com.api.modules.auth.dto.FirebaseLoginRequest;
import com.api.modules.auth.dto.GoogleLoginRequest;
import com.api.modules.auth.dto.LoginRequest;
import com.api.modules.auth.dto.PhoneOtpRequest;
import com.api.modules.auth.dto.PhoneVerifyRequest;
import com.api.modules.auth.dto.RegisterRequest;
import com.api.modules.auth.dto.SetPasswordRequest;
import com.api.modules.auth.dto.UpdateProfileRequest;
import com.api.modules.auth.dto.UserResponse;

@Tag(name = "Authentication", description = "Authentication, registration, phone OTP, and token management")
@RestController
@RequestMapping("/api/auth")
@CrossOrigin(origins = "http://localhost:5173")
public class AuthController {

    private final AuthService authService;
    private final com.api.modules.user.service.UserManagementService userManagement;

    public AuthController(AuthService authService, com.api.modules.user.service.UserManagementService userManagement) {
        this.authService = authService;
        this.userManagement = userManagement;
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

    @PostMapping("/firebase-phone")
    public ResponseEntity<AuthResponse> firebasePhone(@RequestBody FirebaseLoginRequest request) {
        return ResponseEntity.ok(authService.loginWithFirebasePhone(request));
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

    @PutMapping("/me/password")
    public ResponseEntity<AuthResponse> setPassword(
            @RequestHeader(value = "Authorization", required = false) String authorization,
            @RequestBody SetPasswordRequest request) {
        return ResponseEntity.ok(authService.setPassword(bearer(authorization), request));
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
    public ResponseEntity<List<com.api.modules.user.service.UserManagementService.UserView>> getAllUsers(
            @RequestHeader(value = "Authorization", required = false) String authorization) {
        return ResponseEntity.ok(userManagement.list(authorization));
    }
}
