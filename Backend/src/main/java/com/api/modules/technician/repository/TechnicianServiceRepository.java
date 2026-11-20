package com.api.modules.technician.repository;


import com.api.modules.technician.entity.Technician;
import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.api.modules.technician.entity.TechnicianServiceListing;

@Repository
public interface TechnicianServiceRepository extends JpaRepository<TechnicianServiceListing, Long> {

    List<TechnicianServiceListing> findByTechnicianId(Long technicianId);

    Optional<TechnicianServiceListing> findByIdAndTechnicianId(Long id, Long technicianId);
}
