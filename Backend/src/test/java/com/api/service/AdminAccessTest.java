package com.api.service;

import com.api.entity.Users;
import com.api.repository.UserRepository;
import com.api.security.JwtService;
import com.api.exception.ForbiddenException;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class AdminAccessTest {
    @Test void activeMainAdminAndAdminCanUseConsoleButOtherRolesCannot() {
        var users = mock(UserRepository.class);
        var jwt = mock(JwtService.class);
        var service = new AdminService(users, null, null, null, null, jwt, null, null);
        var user = new Users();
        user.setStatus("ACTIVE");
        when(jwt.extractEmail("token")).thenReturn("admin@example.com");
        when(users.findByEmail("admin@example.com")).thenReturn(Optional.of(user));
        for (String role : new String[] {"MAIN_ADMIN", "ADMIN"}) {
            user.setRole(role);
            assertSame(user, service.requireAdmin("Bearer token"));
        }
        for (String role : new String[] {"CUSTOMER", "TECHNICIAN"}) {
            user.setRole(role);
            assertThrows(ForbiddenException.class, () -> service.requireAdmin("Bearer token"));
        }
        user.setRole("MAIN_ADMIN");
        user.setStatus("SUSPENDED");
        assertThrows(ForbiddenException.class, () -> service.requireAdmin("Bearer token"));
    }
}
