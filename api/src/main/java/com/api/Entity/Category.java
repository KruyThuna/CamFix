package com.api.Entity;

import java.util.List;

import com.fasterxml.jackson.annotation.JsonBackReference;

import jakarta.persistence.*;

@Entity
@Table(name = "category")
public class Category {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "category_id")
    private Long categoryId;

    @Column(name = "categoryName", nullable = false, unique = true, length = 100)
    private String categoryName;

    @Column(length = 255)
    private String icon;

    @Column(length = 500)
    private String description;

    @OneToMany(mappedBy = "category", fetch = FetchType.LAZY, cascade = { CascadeType.PERSIST, CascadeType.MERGE })
    @JsonBackReference
    private List<Technician> technicians;

    // Default constructor
    public Category() {
    }

    // Constructor
    public Category(String categoryName, String icon, String description) {
        this.categoryName = categoryName;
        this.icon = icon;
        this.description = description;
    }

    public Long getCategoryId() {
        return categoryId;
    }

    public String getCategoryName() {
        return categoryName;
    }

    public String getIcon() {
        return icon;
    }

    public String getDescription() {
        return description;
    }

    public List<Technician> getTechnicians() {
        return technicians;
    }

    public void setCategoryName(String categoryName) {
        this.categoryName = categoryName;
    }

    public void setIcon(String icon) {
        this.icon = icon;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public void setTechnicians(List<Technician> technicians) {
        this.technicians = technicians;
    }
}