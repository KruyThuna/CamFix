package com.api.dto.Response;

public class CategoryResponse {

    private Long categoryId;
    private String categoryName;
    private String icon;
    private String description;

    public CategoryResponse() {
    }

    public CategoryResponse(Long categoryId, String categoryName, String icon, String description) {
        this.categoryId = categoryId;
        this.categoryName = categoryName;
        this.icon = icon;
        this.description = description;
    }

    public Long getCategoryId() {
        return categoryId;
    }

    public void setCategoryId(Long categoryId) {
        this.categoryId = categoryId;
    }

    public String getCategoryName() {
        return categoryName;
    }

    public void setCategoryName(String categoryName) {
        this.categoryName = categoryName;
    }

    public String getIcon() {
        return icon;
    }

    public void setIcon(String icon) {
        this.icon = icon;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }
}