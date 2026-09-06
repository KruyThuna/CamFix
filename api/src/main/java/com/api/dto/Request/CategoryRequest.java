package com.api.dto.Request;

public class CategoryRequest {

    // @NotBlank(message = "Category name is required")
    // @Size(max = 100, message = "Category name must not exceed 100 characters")
    private String categoryName;
    // @Size(max = 255, message = "Icon must not exceed 255 characters")
    private String icon;
    // @Size(max = 500, message = "Description must not exceed 500 characters")
    private String description;

    public CategoryRequest() {
    }

    public CategoryRequest(String categoryName, String icon, String description) {
        this.categoryName = categoryName;
        this.icon = icon;
        this.description = description;
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