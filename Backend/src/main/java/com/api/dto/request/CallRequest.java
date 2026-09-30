package com.api.dto.request;

import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

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

    public CallRequest() {
    }

    public CallRequest(String calStatus, LocalDateTime startedAt, LocalDateTime endedAt,
            Integer durationSeconnds, LocalDateTime createdAt) {
        this.calStatus = calStatus;
        this.startedAt = startedAt;
        this.endedAt = endedAt;
        this.durationSeconnds = durationSeconnds;
        this.createdAt = createdAt;
    }
}
