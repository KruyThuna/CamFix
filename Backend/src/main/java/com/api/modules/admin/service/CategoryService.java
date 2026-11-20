package com.api.modules.admin.service;

import java.util.List;

import com.api.modules.admin.entity.Category;

public interface CategoryService {

    List<Category> getAllCategories();

    Category getCategoryById(Long categoryId);

    Category createCategory(Category category);

    Category updateCategory(Long categoryId, Category category);

    void deleteCategory(Long categoryId);
}