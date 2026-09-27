package com.api.dto.Technician;

import lombok.Getter;
import lombok.Setter;

/** Body for {@code POST /api/technician/auth/register}. */
@Getter
@Setter
public class TechnicianRegisterRequest {

    private String firstName;
    private String lastName;
    private String email;
    private String password;
    private String phoneNumber;
    private String category;
    private String serviceArea;

    /** Required JPEG or PNG ID-card image, Base64 encoded (maximum 5 MB decoded). */
    private String idCardBase64;
    /** Camera face photo for manual admin review, using the same limits. Leave
     *  blank when verifying identity via {@link #emailOtpCode} instead. */
    private String facePhotoBase64;
    /** Six-digit code issued for the registration phone number. */
    private String otpCode;
    /** Six-digit code issued to {@link #email} via {@code POST
     *  /api/auth/email/request-otp} - an alternative to {@link #facePhotoBase64}
     *  for a technician who'd rather not take a face photo. Exactly one of the
     *  two must be provided. */
    private String emailOtpCode;
}
