package com.api.Service;

import com.api.Entity.Users;
import com.api.Repo.UserRepository;
import com.api.Repo.TechnicianRepository;
import com.api.Repo.JobRepository;
import com.api.Security.JwtService;
import com.api.exception.ForbiddenException;
import com.api.exception.InvalidCredentialsException;
import java.util.List;
import java.util.Locale;
import java.util.NoSuchElementException;
import java.util.Objects;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional
public class UserManagementService {
    private final UserRepository users;
    private final TechnicianRepository technicians;
    private final JwtService jwt;
    private final PasswordEncoder passwords;
    private final AdminService admin;
    private final JobRepository jobs;

    public UserManagementService(UserRepository users, TechnicianRepository technicians,
            JwtService jwt, PasswordEncoder passwords, AdminService admin, JobRepository jobs) {
        this.users = users; this.technicians = technicians; this.jwt = jwt;
        this.passwords = passwords; this.admin = admin;
        this.jobs = jobs;
    }

    public record UserView(Long id, String firstName, String lastName, String email,
            String phoneNumber, String role, String status) {}
    public record CreateAdmin(String firstName, String lastName, String email,
            String phoneNumber, String password) {}
    public record EditUser(String firstName, String lastName, String phoneNumber) {}

    private Users manager(String auth) {
        String token = auth != null && auth.regionMatches(true, 0, "Bearer ", 0, 7)
                ? auth.substring(7).trim() : null;
        String email = jwt.extractEmail(token);
        if (email == null) throw new InvalidCredentialsException("Not authenticated");
        Users actor = users.findByEmail(email)
                .orElseThrow(() -> new InvalidCredentialsException("User not found"));
        if (!"ACTIVE".equalsIgnoreCase(actor.getStatus()) ||
                !("ADMIN".equalsIgnoreCase(actor.getRole()) || "MAIN_ADMIN".equalsIgnoreCase(actor.getRole()))) {
            throw new ForbiddenException("Active Main Admin or Admin access required");
        }
        return actor;
    }

    @Transactional(readOnly = true)
    public List<UserView> list(String auth) {
        Users actor = manager(auth);
        return users.findAll().stream()
                .filter(u -> "MAIN_ADMIN".equalsIgnoreCase(actor.getRole()) || isRegular(u))
                .map(UserManagementService::view).toList();
    }

    public UserView create(String auth, CreateAdmin input) {
        Users actor = manager(auth);
        if (!"MAIN_ADMIN".equalsIgnoreCase(actor.getRole())) throw new ForbiddenException("Only Main Admin can create Admin accounts");
        if (input == null) throw new IllegalArgumentException("Account details are required");
        String email = text(input.email(), "Email", 100).toLowerCase(Locale.ROOT);
        if (!email.matches("[^\\s@]+@[^\\s@]+\\.[^\\s@]+")) throw new IllegalArgumentException("Invalid email");
        String phone = text(input.phoneNumber(), "Phone number", 100);
        if (users.existsByEmail(email) || users.existsByPhoneNumber(phone)) {
            throw new IllegalArgumentException("Email or phone number is already in use");
        }
        if (input.password() == null || input.password().length() < 12 ||
                input.password().getBytes(java.nio.charset.StandardCharsets.UTF_8).length > 72) {
            throw new IllegalArgumentException("Password must be at least 12 characters and no more than 72 UTF-8 bytes");
        }
        Users user = new Users();
        user.setFirstName(text(input.firstName(), "First name", 50));
        user.setLastName(text(input.lastName(), "Last name", 50));
        user.setEmail(email); user.setPhoneNumber(phone);
        user.setPassword(passwords.encode(input.password()));
        user.setRole("ADMIN"); user.setStatus("ACTIVE");
        return view(users.saveAndFlush(user));
    }

    public UserView update(String auth, Long id, EditUser input) {
        Users actor = manager(auth);
        Users user = target(actor, id);
        if (input == null) throw new IllegalArgumentException("User details are required");
        String phone = text(input.phoneNumber(), "Phone number", 100);
        if (!phone.equals(user.getPhoneNumber()) && users.existsByPhoneNumber(phone)) {
            throw new IllegalArgumentException("Phone number is already in use");
        }
        user.setFirstName(text(input.firstName(), "First name", 50));
        user.setLastName(text(input.lastName(), "Last name", 50));
        user.setPhoneNumber(phone);
        return view(users.saveAndFlush(user));
    }

    public void delete(String auth, Long id) {
        Users actor = manager(auth);
        Users user = target(actor, id);
        if (jobs.existsByCustomerUserId(id)) {
            throw new IllegalArgumentException("Cannot delete a user with job history");
        }
        technicians.findByUsers_UserId(id).ifPresent(t -> {
            if (jobs.existsByTechnicianId(t.getTechnicianId())) {
                throw new IllegalArgumentException("Cannot delete a technician with job history");
            }
            admin.deleteTechnician(t.getTechnicianId());
        });
        users.delete(user);
        // FK violations roll the whole transaction back, including technician deletion.
        users.flush();
    }

    private Users target(Users actor, Long id) {
        Users target = users.findById(id).orElseThrow(() -> new NoSuchElementException("User not found"));
        if (Objects.equals(actor.getUserId(), id) || "MAIN_ADMIN".equalsIgnoreCase(target.getRole()) ||
                (!"MAIN_ADMIN".equalsIgnoreCase(actor.getRole()) && !isRegular(target))) {
            throw new ForbiddenException("This account is protected");
        }
        return target;
    }

    private static boolean isRegular(Users user) {
        return "CUSTOMER".equalsIgnoreCase(user.getRole()) || "TECHNICIAN".equalsIgnoreCase(user.getRole());
    }

    private static String text(String value, String label, int max) {
        if (value == null || value.isBlank() || value.trim().length() > max) {
            throw new IllegalArgumentException(label + " is required (maximum " + max + " characters)");
        }
        return value.trim();
    }

    private static UserView view(Users u) {
        return new UserView(u.getUserId(), u.getFirstName(), u.getLastName(), u.getEmail(),
                u.getPhoneNumber(), u.getRole(), u.getStatus());
    }
}
