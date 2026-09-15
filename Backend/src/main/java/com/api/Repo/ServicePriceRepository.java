package com.api.Repo;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.api.Entity.ServicePrice;

@Repository
public interface ServicePriceRepository extends JpaRepository<ServicePrice, Long> {

    Optional<ServicePrice> findByCategoryId(Long categoryId);
}
