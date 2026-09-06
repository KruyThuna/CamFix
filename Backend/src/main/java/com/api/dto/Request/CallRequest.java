package com.api.dto.Request;

import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@AllArgsConstructor
@NoArgsConstructor
@Data
public class CallRequest {
    @NotBlank(message = "status is reqire ")
    @Column(name = "call_status")
    private String calStatus;

    @NotBlank(message = "start is require")
    @Column(name = "start_at")
    private LocalDateTime startedAt;

    @NotBlank(message = "ended_at requre")
    @Column(name = "ended_at")
    private LocalDateTime endedAt;
    @NotBlank(message = "duration_seconds requre")
    @Column(name = "duration_seconds")
    private Integer durationSeconnds;

    @NotBlank(message = "create_at is requre")
    @Column(name = "created_at")
    private LocalDateTime createdAt;

}
