package com.api.dto.Auth;

/** Body for {@code PUT /api/auth/me}. All fields optional — only non-null,
 *  non-blank ones are applied. */
public class UpdateProfileRequest {

    private String firstName;
    private String lastName;
    private String phoneNumber;
    /** ISO-8601 date, yyyy-MM-dd. */
    private String dateOfBirth;

    public UpdateProfileRequest() {
    }

    public String getFirstName() {
        return firstName;
    }

    public void setFirstName(String firstName) {
        this.firstName = firstName;
    }

    public String getLastName() {
        return lastName;
    }

    public void setLastName(String lastName) {
        this.lastName = lastName;
    }

    public String getPhoneNumber() {
        return phoneNumber;
    }

    public void setPhoneNumber(String phoneNumber) {
        this.phoneNumber = phoneNumber;
    }

    public String getDateOfBirth() {
        return dateOfBirth;
    }

    public void setDateOfBirth(String dateOfBirth) {
        this.dateOfBirth = dateOfBirth;
    }
}
