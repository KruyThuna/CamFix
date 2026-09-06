package com.api.Service;

import java.util.List;
import java.util.Map;

import com.api.Entity.Users;
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

public interface AuthService {

    /** The user identified by the bearer [token]. */
    UserResponse currentUser(String token);

    /** Apply the non-empty fields of [request] to the token's user. */
    UserResponse updateCurrentUser(String token, UpdateProfileRequest request);

    /** Create a new user and return a freshly issued auth token. */
    AuthResponse register(RegisterRequest request);

    /** Verify email + password and return an auth token. */
    AuthResponse login(LoginRequest request);

    /** Verify a Google ID token; create the user on first sign-in. */
    AuthResponse loginWithGoogle(GoogleLoginRequest request);

    /** Generate + send a one-time code by SMS to the given phone number. */
    Map<String, Object> requestPhoneOtp(PhoneOtpRequest request);

    /** Verify a phone OTP; create the user on first sign-in. */
    AuthResponse verifyPhoneOtp(PhoneVerifyRequest request);

    /** Generate + send a one-time code by email to the given address. */
    Map<String, Object> requestEmailOtp(EmailOtpRequest request);

    /** Verify an email OTP; create the user on first sign-in. */
    AuthResponse verifyEmailOtp(EmailVerifyRequest request);

    List<Users> findAllUsers();

}
