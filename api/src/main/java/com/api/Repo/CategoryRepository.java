package com.api.Repo;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.api.Entity.Category;

@Repository
public interface CategoryRepository extends JpaRepository<Category, Long> {

    Optional<Category> findByCategoryId(Long categoryId);

    Optional<Category> findByCategoryName(String categoryName);

    boolean existsByCategoryName(String categoryName);
}