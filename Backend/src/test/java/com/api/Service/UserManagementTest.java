package com.api.service;

import com.api.entity.Users;
import com.api.repository.UserRepository;
import com.api.repository.TechnicianRepository;
import com.api.repository.JobRepository;
import com.api.security.JwtService;
import com.api.exception.ForbiddenException;
import org.junit.jupiter.api.Test;
import org.springframework.security.crypto.password.PasswordEncoder;
import java.util.List;
import java.util.Optional;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class UserManagementTest {
    private final UserRepository users = mock(UserRepository.class);
    private final TechnicianRepository technicians = mock(TechnicianRepository.class);
    private final JwtService jwt = mock(JwtService.class);
    private final PasswordEncoder passwords = mock(PasswordEncoder.class);
    private final JobRepository jobs = mock(JobRepository.class);
    private final AdminService admin = mock(AdminService.class);
    private final UserManagementService service = new UserManagementService(
            users, technicians, jwt, passwords, admin, jobs);

    private Users user(long id, String role) {
        Users u = new Users(); u.setUserId(id); u.setRole(role); u.setStatus("ACTIVE");
        u.setEmail(id + "@example.com"); return u;
    }
    private Users actor(String role) {
        Users u = user(1, role);
        when(jwt.extractEmail("token")).thenReturn(u.getEmail());
        when(users.findByEmail(u.getEmail())).thenReturn(Optional.of(u));
        return u;
    }

    @Test void onlyAdminCanCreateAdminsAndRoleIsAssignedByServer() {
        actor("ADMIN");
        var input = new UserManagementService.CreateAdmin("First", "Last", "new@example.com", "012345678", "strong-password-123");
        assertThrows(ForbiddenException.class, () -> service.create("Bearer token", input));
        verify(users, never()).saveAndFlush(any());
        actor("MAIN_ADMIN");
        when(passwords.encode(input.password())).thenReturn("hash");
        when(users.saveAndFlush(any())).thenAnswer(i -> i.getArgument(0));
        assertEquals("ADMIN", service.create("Bearer token", input).role());
        var saved = org.mockito.ArgumentCaptor.forClass(Users.class);
        verify(users).saveAndFlush(saved.capture());
        assertEquals("hash", saved.getValue().getPassword());
    }

    @Test void adminCannotDeleteStaffOrSelfButCanDeleteCustomer() {
        actor("ADMIN");
        for (Users target : List.of(user(1, "ADMIN"), user(2, "MAIN_ADMIN"), user(3, "ADMIN"))) {
            when(users.findById(target.getUserId())).thenReturn(Optional.of(target));
            assertThrows(ForbiddenException.class, () -> service.delete("Bearer token", target.getUserId()));
        }
        verify(users, never()).delete(any());
        Users customer = user(4, "CUSTOMER");
        when(users.findById(4L)).thenReturn(Optional.of(customer));
        service.delete("Bearer token", 4L);
        verify(users).delete(customer); verify(users).flush();
    }

    @Test void customersAndSuspendedManagersCannotManageUsers() {
        actor("CUSTOMER");
        assertThrows(ForbiddenException.class, () -> service.list("Bearer token"));
        actor("ADMIN").setStatus("SUSPENDED");
        assertThrows(ForbiddenException.class, () -> service.list("Bearer token"));
    }

    @Test void adminListExcludesStaffAccounts() {
        actor("ADMIN");
        when(users.findAll()).thenReturn(List.of(user(1, "ADMIN"), user(2, "MAIN_ADMIN"), user(3, "CUSTOMER")));
        assertEquals(List.of(3L), service.list("Bearer token").stream().map(UserManagementService.UserView::id).toList());
    }

    @Test void deletionPreservesJobHistory() {
        actor("ADMIN");
        when(users.findById(4L)).thenReturn(Optional.of(user(4, "CUSTOMER")));
        when(jobs.existsByCustomerUserId(4L)).thenReturn(true);
        assertThrows(IllegalArgumentException.class, () -> service.delete("Bearer token", 4L));
        verify(users, never()).delete(any());
    }

    @Test void mainAdminCanManageAndDeleteAdminButNeverMainAdmin() {
        actor("MAIN_ADMIN");
        Users target = user(2, "ADMIN");
        when(users.findById(2L)).thenReturn(Optional.of(target));
        when(users.saveAndFlush(any())).thenAnswer(i -> i.getArgument(0));
        service.update("Bearer token", 2L,
                new UserManagementService.EditUser("New", "Name", "012345678"));
        assertEquals("New", target.getFirstName());
        service.delete("Bearer token", 2L);
        verify(users).delete(target);

        Users main = user(3, "MAIN_ADMIN");
        when(users.findById(3L)).thenReturn(Optional.of(main));
        assertThrows(ForbiddenException.class, () -> service.delete("Bearer token", 3L));
        assertThrows(ForbiddenException.class, () -> service.update("Bearer token", 3L,
                new UserManagementService.EditUser("No", "Change", "012345679")));
        verify(users, never()).delete(main);
    }

    @Test void passwordResetPreservesAdminHierarchy() {
        actor("ADMIN");
        for (Users target : List.of(user(1, "ADMIN"), user(2, "MAIN_ADMIN"), user(3, "ADMIN"))) {
            when(users.findById(target.getUserId())).thenReturn(Optional.of(target));
            assertThrows(ForbiddenException.class,
                    () -> service.resetPassword("Bearer token", target.getUserId()));
        }
        verifyNoInteractions(admin);
        when(users.findById(4L)).thenReturn(Optional.of(user(4, "CUSTOMER")));
        service.resetPassword("Bearer token", 4L);
        verify(admin).resetUserPassword(4L);
        actor("MAIN_ADMIN");
        service.resetPassword("Bearer token", 3L);
        verify(admin).resetUserPassword(3L);
        assertThrows(ForbiddenException.class, () -> service.resetPassword("Bearer token", 2L));
    }

    @Test void adminCannotEditOtherAdmins() {
        actor("ADMIN");
        when(users.findById(2L)).thenReturn(Optional.of(user(2, "ADMIN")));
        assertThrows(ForbiddenException.class, () -> service.update("Bearer token", 2L,
                new UserManagementService.EditUser("No", "Change", "012345679")));
        verify(users, never()).saveAndFlush(any());
    }
}
