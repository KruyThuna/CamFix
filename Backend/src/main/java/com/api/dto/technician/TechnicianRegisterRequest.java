package com.api.dto.technician;

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

    /** Code from {@code POST /api/technician/auth/phone/request-otp} - the
     *  phone number must be verified before the account is created. */
    private String otpCode;
}
