package com.api.Entity;

import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.Table;

@Entity
@Table(name = "password_reset_token")

public class PasswordToken {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long resetId;

    @JoinColumn(name = "user_id")
    private Long userId;

    @Column(name = "token")
    private String token;

    @Column(name = "expires_at_date")
    private LocalDateTime expiresAtDate;

    @Column(name = "is_used")
    private LocalDateTime is_Used;

    @Column(name = "create_at")
    private LocalDateTime createAt;

}
