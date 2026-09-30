package com.api.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.api.entity.TechnicianServicePhoto;

@Repository
public interface TechnicianServicePhotoRepository extends JpaRepository<TechnicianServicePhoto, Long> {
}
