package com.api.Repo;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.api.Entity.TechnicianServicePhoto;

@Repository
public interface TechnicianServicePhotoRepository extends JpaRepository<TechnicianServicePhoto, Long> {
}
