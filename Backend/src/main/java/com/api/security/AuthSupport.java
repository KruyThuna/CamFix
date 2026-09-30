package com.api.security;

import org.springframework.stereotype.Component;

import com.api.entity.Users;
import com.api.repository.UserRepository;
import com.api.exception.InvalidCredentialsException;

/**
 * Shared bearer-token -> {@link Users} resolver. The project has no Spring
 * Security filter chain (everything under {@code /api/**} is permitAll in
 * {@code SwaggerConfig}), so controllers that need the caller identity read the
 * {@code Authorization} header and pass it here.
 */
@Component
public class AuthSupport {

    private final JwtService jwtService;
    private final UserRepository userRepository;

    public AuthSupport(JwtService jwtService, UserRepository userRepository) {
        this.jwtService = jwtService;
        this.userRepository = userRepository;
    }

    /** @throws InvalidCredentialsException (-> 401) when the token is missing/invalid/unknown. */
    public Users currentUser(String authorizationHeader) {
        String email = jwtService.extractEmail(bearer(authorizationHeader));
        if (email == null) {
            throw new InvalidCredentialsException("Not authenticated");
        }
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new InvalidCredentialsException("User not found"));
    }

    public static String bearer(String header) {
        if (header == null) {
            return null;
        }
        return header.regionMatches(true, 0, "Bearer ", 0, 7)
                ? header.substring(7).trim()
                : header.trim();
    }
}
