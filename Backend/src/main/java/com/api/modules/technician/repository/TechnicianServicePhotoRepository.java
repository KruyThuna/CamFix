package com.api.modules.technician.repository;


import com.api.modules.technician.entity.Technician;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.api.modules.technician.entity.TechnicianServicePhoto;

@Repository
public interface TechnicianServicePhotoRepository extends JpaRepository<TechnicianServicePhoto, Long> {
}
