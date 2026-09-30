package com.api.dto.response;

import java.time.LocalDateTime;
import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Builder
public class CallHistoryResponse {
    private Long callId;
    private Long userId;
    private String userName;
    private Long technicianId;
    private String technicianName;
    private String callStatus;
    private LocalDateTime startedAt;
    private LocalDateTime endedAt;
    private Integer durationSeconds;
    private LocalDateTime createdAt;

    public CallHistoryResponse() {
    }

    public CallHistoryResponse(Long callId, Long userId, String userName, Long technicianId,
            String technicianName, String callStatus, LocalDateTime startedAt,
            LocalDateTime endedAt, Integer durationSeconds, LocalDateTime createdAt) {
        this.callId = callId;
        this.userId = userId;
        this.userName = userName;
        this.technicianId = technicianId;
        this.technicianName = technicianName;
        this.callStatus = callStatus;
        this.startedAt = startedAt;
        this.endedAt = endedAt;
        this.durationSeconds = durationSeconds;
        this.createdAt = createdAt;
    }
}
