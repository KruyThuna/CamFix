package com.api.Service.implement;

import java.util.List;

import org.springframework.stereotype.Service;

import com.api.Entity.Category;
import com.api.Repo.CategoryRepository;
import com.api.Service.CategoryService;

@Service
public class CategoryServiceImpl implements CategoryService {

    private final CategoryRepository categoryRepository;

    public CategoryServiceImpl(CategoryRepository categoryRepository) {
        this.categoryRepository = categoryRepository;
    }

    @Override
    public void deleteCategory(Long categoryId) {
        if (!categoryRepository.existsById(categoryId)) {
            throw new RuntimeException("Category not found with id: " + categoryId);
        }
        categoryRepository.deleteById(categoryId);
    }

    @Override
    public Category getCategoryById(Long categoryId) {
        return categoryRepository.findById(categoryId)
                .orElseThrow(() -> new RuntimeException("Category not found with id: " + categoryId));
    }

    @Override
    public Category createCategory(Category category) {
        if (category.getCategoryName() != null && categoryRepository.existsByCategoryName(category.getCategoryName())) {
            throw new RuntimeException("Category already exists with name: " + category.getCategoryName());
        }

        return categoryRepository.save(category);
    }

    @Override
    public Category updateCategory(Long categoryId, Category category) {
        Category existing = categoryRepository.findById(categoryId)
                .orElseThrow(() -> new RuntimeException("Category not found with id: " + categoryId));

        if (category.getCategoryName() != null && !category.getCategoryName().isBlank()) {
            existing.setCategoryName(category.getCategoryName());
        }

        if (category.getIcon() != null) {
            existing.setIcon(category.getIcon());
        }

        if (category.getDescription() != null) {
            existing.setDescription(category.getDescription());
        }

        return categoryRepository.save(existing);
    }

    @Override
    public List<Category> getAllCategories() {
        return categoryRepository.findAll();
    }
}