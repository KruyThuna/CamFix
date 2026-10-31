package com.api.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.api.entity.AppBanner;

@Repository
public interface AppBannerRepository extends JpaRepository<AppBanner, Long> {

    List<AppBanner> findByActiveTrueOrderByDisplayOrderAscIdDesc();

    List<AppBanner> findAllByOrderByDisplayOrderAscIdDesc();
}
