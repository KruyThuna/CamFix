package com.api.dto.Auth;

import com.api.Entity.Users;

/** Safe view of a user (no password hash) returned by {@code /api/auth/me}. */
public class UserResponse {

    private Long id;
    private String firstName;
    private String lastName;
    private String email;
    private String phoneNumber;
    private String role;
    private String status;
    private String dateOfBirth;

    public UserResponse() {
    }

    public static UserResponse from(Users u) {
        UserResponse r = new UserResponse();
        r.id = u.getUserId();
        r.firstName = u.getFirstName();
        r.lastName = u.getLastName();
        r.email = u.getEmail();
        r.phoneNumber = u.getPhoneNumber();
        r.role = u.getRole();
        r.status = u.getStatus();
        r.dateOfBirth = u.getDateOfBirth() == null ? null : u.getDateOfBirth().toString();
        return r;
    }

    public Long getId() {
        return id;
    }

    public String getFirstName() {
        return firstName;
    }

    public String getLastName() {
        return lastName;
    }

    public String getEmail() {
        return email;
    }

    public String getPhoneNumber() {
        return phoneNumber;
    }

    public String getRole() {
        return role;
    }

    public String getStatus() {
        return status;
    }

    public String getDateOfBirth() {
        return dateOfBirth;
    }
}
