package com.api.Controller;

import java.util.List;

import org.springframework.web.bind.annotation.*;

import com.api.Entity.Category;
import com.api.Service.CategoryService;

@RestController
@RequestMapping("/api/category")
public class CategoryController {

    private final CategoryService categoryService;

    public CategoryController(CategoryService categoryService) {
        this.categoryService = categoryService;
    }

    // Get All Categories
    @GetMapping
    public List<Category> getAllCategories() {
        return categoryService.getAllCategories();
    }

    // Get Category By ID
    @GetMapping("/{id}")
    public Category getCategoryById(@PathVariable Long id) {
        return categoryService.getCategoryById(id);
    }

    // Create Category
    @PostMapping
    public Category createCategory(@RequestBody Category category) {
        return categoryService.createCategory(category);
    }

    // Update Category
    @PutMapping("/{id}")
    public Category updateCategory(@PathVariable Long id,
            @RequestBody Category category) {
        return categoryService.updateCategory(id, category);
    }

    // Delete Category
    @DeleteMapping("/{id}")
    public void deleteCategory(@PathVariable Long id) {
        categoryService.deleteCategory(id);
    }
}