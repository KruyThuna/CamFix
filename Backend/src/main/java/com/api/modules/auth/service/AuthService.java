package com.api.modules.auth.service;

import java.util.List;
import java.util.Map;

import com.api.modules.user.entity.Users;
import com.api.modules.auth.dto.AuthResponse;
import com.api.modules.auth.dto.EmailOtpRequest;
import com.api.modules.auth.dto.EmailVerifyRequest;
import com.api.modules.auth.dto.GoogleLoginRequest;
import com.api.modules.auth.dto.LoginRequest;
import com.api.modules.auth.dto.PhoneOtpRequest;
import com.api.modules.auth.dto.PhoneVerifyRequest;
import com.api.modules.auth.dto.RegisterRequest;
import com.api.modules.auth.dto.SetPasswordRequest;
import com.api.modules.auth.dto.UpdateProfileRequest;
import com.api.modules.auth.dto.UserResponse;

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
