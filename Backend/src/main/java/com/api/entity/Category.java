package com.api.entity;

import java.util.List;

import com.fasterxml.jackson.annotation.JsonBackReference;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "category")
@Getter
@Setter
@NoArgsConstructor
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

    // Constructor
    public Category(String categoryName, String icon, String description) {
        this.categoryName = categoryName;
        this.icon = icon;
        this.description = description;
    }
}
