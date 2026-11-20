package com.api.modules.review.dto;


import com.api.modules.review.entity.Review;
public class FavoriteRequest {
    private Long technicianId;

    public Long getTechnicianId() {
        return technicianId;
    }

    public void setTechnicianId(Long technicianId) {
        this.technicianId = technicianId;
    }
}
