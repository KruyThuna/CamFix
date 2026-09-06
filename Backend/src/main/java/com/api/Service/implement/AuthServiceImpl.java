package com.api.Service.implement;

import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import com.api.Entity.Users;
import com.api.Repo.UserRepository;
import com.api.Security.GoogleTokenVerifier;
import com.api.Security.GoogleTokenVerifier.GooglePrincipal;
import com.api.Security.JwtService;
import com.api.Service.AuthService;
import com.api.Service.OtpService;
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
import com.api.exception.EmailAlreadyExistsException;
import com.api.exception.InvalidCredentialsException;

@Service
public class AuthServiceImpl implements AuthService {

    private static final String DEFAULT_ROLE = "CUSTOMER";
    private static final String DEFAULT_STATUS = "ACTIVE";

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final GoogleTokenVerifier googleVerifier;
    private final OtpService otpService;

    public AuthServiceImpl(UserRepository userRepository,
            PasswordEncoder passwordEncoder,
            JwtService jwtService,
            GoogleTokenVerifier googleVerifier,
            OtpService otpService) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
        this.googleVerifier = googleVerifier;
        this.otpService = otpService;
    }

    // --- Email + password -------------------------------------------------

    @Override
    public AuthResponse register(RegisterRequest request) {
        // Only email + password are mandatory; the sign-up form is minimal.
        // Missing name / phone are synthesised (the schema has them NOT NULL).
        requireText(request.getEmail(), "email is required");
        requireText(request.getPassword(), "password is required");

        String email = request.getEmail().trim().toLowerCase();
        if (userRepository.existsByEmail(email)) {
            throw new EmailAlreadyExistsException("Email already registered: " + email);
        }

        String localPart = email.contains("@") ? email.substring(0, email.indexOf('@')) : email;
        String phone = isBlank(request.getPhoneNumber())
                ? "email:" + email
                : request.getPhoneNumber().trim();

        Users user = new Users();
        user.setFirstName(blankTo(request.getFirstName(), localPart));
        user.setLastName(blankTo(request.getLastName(), "-"));
        user.setEmail(email);
        user.setPhoneNumber(phone);
        user.setPassword(passwordEncoder.encode(request.getPassword()));
        user.setDateOfBirth(parseDateOfBirth(request.getDateOfBirth()));
        user.setRole(DEFAULT_ROLE);
        user.setStatus(DEFAULT_STATUS);

        Users saved = userRepository.save(user);
        return tokenFor(saved, "Registration successful");
    }

    @Override
    public AuthResponse login(LoginRequest request) {
        requireText(request.getEmail(), "email is required");
        requireText(request.getPassword(), "password is required");

        Users user = userRepository.findByEmail(request.getEmail().trim().toLowerCase())
                .orElseThrow(() -> new InvalidCredentialsException("Invalid email or password"));

        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new InvalidCredentialsException("Invalid email or password");
        }
        return tokenFor(user, "Login successful");
    }

    // --- Google --------------------------------------------------------------

    @Override
    public AuthResponse loginWithGoogle(GoogleLoginRequest request) {
        GooglePrincipal principal = googleVerifier.verify(request == null ? null : request.getIdToken());

        Users user = userRepository.findByEmail(principal.email()).orElseGet(() -> {
            Users u = new Users();
            u.setEmail(principal.email());
            u.setFirstName(blankTo(principal.givenName(), "Google"));
            u.setLastName(blankTo(principal.familyName(), "User"));
            // Phone_number is NOT NULL + UNIQUE in the schema; social users have none.
            u.setPhoneNumber("google:" + principal.email());
            u.setPassword(unusablePassword());
            u.setRole(DEFAULT_ROLE);
            u.setStatus(DEFAULT_STATUS);
            return userRepository.save(u);
        });
        return tokenFor(user, "Google login successful");
    }

    // --- Phone + OTP -----------------------------------------------------

    @Override
    public Map<String, Object> requestPhoneOtp(PhoneOtpRequest request) {
        String phone = normalisePhone(request == null ? null : request.getPhoneNumber());
        String code = otpService.issuePhone(phone);
        return otpBody("OTP sent to " + phone, code);
    }

    @Override
    public AuthResponse verifyPhoneOtp(PhoneVerifyRequest request) {
        String phone = normalisePhone(request == null ? null : request.getPhoneNumber());
        String code = request == null ? null : request.getCode();
        requireText(code, "code is required");

        if (!otpService.verify(phone, code.trim())) {
            throw new InvalidCredentialsException("Invalid or expired code");
        }

        String syntheticEmail = syntheticPhoneEmail(phone);
        // Match on the number, then fall back to the synthetic e-mail so
        // accounts created before phone numbers were canonicalised (stored
        // with spaces) are still recognised instead of colliding on insert.
        Users user = userRepository.findByPhoneNumber(phone)
                .or(() -> userRepository.findByEmail(syntheticEmail))
                .map(u -> {
                    if (!phone.equals(u.getPhoneNumber())) {
                        u.setPhoneNumber(phone); // heal legacy formatting
                        return userRepository.save(u);
                    }
                    return u;
                })
                .orElseGet(() -> {
                    Users u = new Users();
                    u.setPhoneNumber(phone);
                    u.setFirstName("User");
                    u.setLastName(
                            phone.length() >= 4 ? phone.substring(phone.length() - 4) : phone);
                    // Email is NOT NULL + UNIQUE in the schema.
                    u.setEmail(syntheticEmail);
                    u.setPassword(unusablePassword());
                    u.setRole(DEFAULT_ROLE);
                    u.setStatus(DEFAULT_STATUS);
                    return userRepository.save(u);
                });
        return tokenFor(user, "Phone login successful");
    }

    // --- Email + OTP -----------------------------------------------------------

    @Override
    public Map<String, Object> requestEmailOtp(EmailOtpRequest request) {
        String email = normaliseEmail(request == null ? null : request.getEmail());
        String code = otpService.issueEmail(email);
        return otpBody("OTP sent to " + email, code);
    }

    @Override
    public AuthResponse verifyEmailOtp(EmailVerifyRequest request) {
        String email = normaliseEmail(request == null ? null : request.getEmail());
        String code = request == null ? null : request.getCode();
        requireText(code, "code is required");

        if (!otpService.verify(email, code.trim())) {
            throw new InvalidCredentialsException("Invalid or expired code");
        }

        Users user = userRepository.findByEmail(email).orElseGet(() -> {
            Users u = new Users();
            u.setEmail(email);
            String localPart = email.contains("@") ? email.substring(0, email.indexOf('@')) : email;
            u.setFirstName(localPart);
            u.setLastName("-");
            // Phone_number is NOT NULL + UNIQUE; email-first users have none.
            u.setPhoneNumber("email:" + email);
            u.setPassword(unusablePassword());
            u.setRole(DEFAULT_ROLE);
            u.setStatus(DEFAULT_STATUS);
            return userRepository.save(u);
        });
        return tokenFor(user, "Email login successful");
    }

    // --- Current user (bearer token) --------------------------------------

    @Override
    public UserResponse currentUser(String token) {
        return UserResponse.from(userFromToken(token));
    }

    @Override
    public UserResponse updateCurrentUser(String token, UpdateProfileRequest request) {
        Users user = userFromToken(token);
        if (request != null) {
            if (!isBlank(request.getFirstName())) {
                user.setFirstName(request.getFirstName().trim());
            }
            if (!isBlank(request.getLastName())) {
                user.setLastName(request.getLastName().trim());
            }
            if (!isBlank(request.getPhoneNumber())) {
                String phone = request.getPhoneNumber().trim();
                if (!phone.equals(user.getPhoneNumber())
                        && userRepository.existsByPhoneNumber(phone)) {
                    throw new IllegalArgumentException("Phone number already in use");
                }
                user.setPhoneNumber(phone);
            }
            if (request.getDateOfBirth() != null) {
                user.setDateOfBirth(parseDateOfBirth(request.getDateOfBirth()));
            }
        }
        return UserResponse.from(userRepository.save(user));
    }

    private Users userFromToken(String token) {
        String email = jwtService.extractEmail(token);
        if (email == null) {
            throw new InvalidCredentialsException("Not authenticated");
        }
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new InvalidCredentialsException("User not found"));
    }

    // --- Shared ----------------------------------------------------------------

    private Map<String, Object> otpBody(String message, String code) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("message", message);
        if (otpService.isExposeCode() && code != null) {
            // Returned only while app.otp.expose-code=true, so the flow is
            // testable without live SMS / email delivery.
            body.put("devCode", code);
        }
        return body;
    }

    @Override
    public List<Users> findAllUsers() {
        return userRepository.findAll();
    }

    private AuthResponse tokenFor(Users user, String message) {
        return new AuthResponse(message, jwtService.generateToken(user.getEmail()));
    }

    /** A BCrypt hash of a random value - satisfies the NOT NULL Password_hash
     *  column for social / phone users while never matching any real password. */
    private String unusablePassword() {
        return passwordEncoder.encode("google-oauth-" + UUID.randomUUID());
    }

    /** Canonical phone form: a leading '+' (if present) followed by digits
     *  only. "+855 97 8068 525", "097 8068 525" and "+855978068525" all
     *  collapse to the same value so lookups are stable. Rejects anything
     *  that isn't a plausible mobile number so no OTP is sent to junk. */
    private static String normalisePhone(String raw) {
        requireText(raw, "phoneNumber is required");
        String trimmed = raw.trim();
        String digits = trimmed.replaceAll("\\D", "");
        String canonical = trimmed.startsWith("+") ? "+" + digits : digits;
        assertPlausiblePhone(digits);
        return canonical;
    }

    private static final java.util.regex.Pattern REPEATED_DIGITS =
            java.util.regex.Pattern.compile("^(\\d)\\1+$");

    /** Basic sanity check - not a full libphonenumber, just enough to stop an
     *  OTP going to something that can't be a phone. */
    private static void assertPlausiblePhone(String digits) {
        if (digits.length() < 8 || digits.length() > 15
                || REPEATED_DIGITS.matcher(digits).matches()) {
            throw new IllegalArgumentException("Enter a valid phone number");
        }
        if (digits.startsWith("855")) {
            String nsn = digits.substring(3);
            while (nsn.startsWith("0")) {
                nsn = nsn.substring(1);
            }
            // Cambodian mobile subscriber numbers are 8 or 9 digits.
            if (nsn.length() < 8 || nsn.length() > 9) {
                throw new IllegalArgumentException(
                        "Enter a valid Cambodian phone number");
            }
        }
    }

    /** Placeholder e-mail for phone-first accounts (the schema needs a unique,
     *  non-null e-mail). Digits only, so it is independent of "+"/spacing. */
    private static String syntheticPhoneEmail(String phone) {
        return phone.replaceAll("\\D", "") + "@phone.camfix.local";
    }

    private static String normaliseEmail(String raw) {
        requireText(raw, "email is required");
        return raw.trim().toLowerCase();
    }

    private static boolean isBlank(String value) {
        return value == null || value.isBlank();
    }

    private static String blankTo(String value, String fallback) {
        return isBlank(value) ? fallback : value.trim();
    }

    private static void requireText(String value, String message) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException(message);
        }
    }

    private static LocalDate parseDateOfBirth(String raw) {
        if (raw == null || raw.isBlank()) {
            return null;
        }
        try {
            return LocalDate.parse(raw.trim());
        } catch (DateTimeParseException e) {
            throw new IllegalArgumentException("dateOfBirth must be an ISO date (yyyy-MM-dd)");
        }
    }
}
