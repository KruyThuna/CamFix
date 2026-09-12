package com.api.dto.Request;

import com.api.Entity.Category;

public class TechnicianRequest {
    private Long technicianId;
    private Category category;
    private int experienceYear;
    private String description;
    public TechnicianRequest() {
    }

    public Long getTechnicianId() {
        return technicianId;
    }

    public Category getCategory() {
        return category;
    }

    public int getExperienceYear() {
        return experienceYear;
    }

    public String getDescription() {
        return description;
    }

    public void setTechnicianId(Long technicianId) {
        this.technicianId = technicianId;
    }

    public void setCategory(Category category) {
        this.category = category;
    }

    public void setExperienceYear(int experienceYear) {
        this.experienceYear = experienceYear;
    }

    public void setDescription(String description) {
        this.description = description;
    }
}