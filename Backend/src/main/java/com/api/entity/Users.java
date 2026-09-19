package com.api.entity;

import java.time.LocalDate;
import java.time.LocalDateTime;

import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import com.fasterxml.jackson.annotation.JsonIgnore;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "users")
@Getter
@Setter
@NoArgsConstructor
public class Users {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "Userid")
    private Long userId;

    @Column(name = "Full_name", nullable = false, length = 50)
    private String firstName;

    @Column(name = "Last_name", nullable = false, length = 50)
    private String lastName;

    @Column(name = "DateofBirth")
    private LocalDate dateOfBirth;

    @Column(name = "Email", unique = true, nullable = false, length = 100)
    private String email;

    @Column(name = "Phone_number", unique = true, nullable = false, length = 100)
    private String phoneNumber;

    @JsonIgnore
    @Column(name = "Password_hash", nullable = false, length = 100)
    private String password;

    @Column(name = "Profile_image", length = 500)
    private String profileImage;

    // DB column is enum('ADMIN','TECHNICIAN','CUSTOMER')
    @Column(name = "ROLE", nullable = false, length = 20)
    private String role;

    // DB column is enum('SUSPENDED','INACTIVE','ACTIVE')
    @Column(name = "STATUS", nullable = false, length = 20)
    private String status;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    public Users(Long userId, String firstName, String lastName, LocalDate dateOfBirth, String email, String password,
            String role) {
        this.userId = userId;
        this.firstName = firstName;
        this.lastName = lastName;
        this.dateOfBirth = dateOfBirth;
        this.email = email;
        this.password = password;
        this.role = role;
    }
}
