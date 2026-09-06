package com.api.dto.Request;

public class StartCallRequest {
    private Long userId;

    public Long getUserId() {
        return userId;
    }

    public Long getTechnicianId() {
        return technicianId;
    }

    private Long technicianId;

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public void setTechnicianId(Long technicianId) {
        this.technicianId = technicianId;
    }
}
