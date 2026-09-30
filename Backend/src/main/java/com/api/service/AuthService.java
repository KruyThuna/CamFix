package com.api.service;

import java.util.List;
import java.util.Map;

import com.api.entity.Users;
import com.api.dto.auth.AuthResponse;
import com.api.dto.auth.EmailOtpRequest;
import com.api.dto.auth.EmailVerifyRequest;
import com.api.dto.auth.GoogleLoginRequest;
import com.api.dto.auth.LoginRequest;
import com.api.dto.auth.PhoneOtpRequest;
import com.api.dto.auth.PhoneVerifyRequest;
import com.api.dto.auth.RegisterRequest;
import com.api.dto.auth.SetPasswordRequest;
import com.api.dto.auth.UpdateProfileRequest;
import com.api.dto.auth.UserResponse;

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

    /** Set a new password for the bearer token's user - used to finish the
     *  "forgot password" flow (which authenticates via email OTP first) and
     *  doubles as a normal "change password" for any signed-in user. */
    AuthResponse setPassword(String token, SetPasswordRequest request);

    List<Users> findAllUsers();

}
