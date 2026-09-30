package com.api.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.api.entity.TechnicianServiceListing;

@Repository
public interface TechnicianServiceRepository extends JpaRepository<TechnicianServiceListing, Long> {

    List<TechnicianServiceListing> findByTechnicianId(Long technicianId);

    Optional<TechnicianServiceListing> findByIdAndTechnicianId(Long id, Long technicianId);
}
