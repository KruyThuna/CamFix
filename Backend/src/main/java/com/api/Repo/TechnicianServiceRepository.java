package com.api.Repo;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.api.Entity.TechnicianServiceListing;

@Repository
public interface TechnicianServiceRepository extends JpaRepository<TechnicianServiceListing, Long> {

    List<TechnicianServiceListing> findByTechnicianId(Long technicianId);

    Optional<TechnicianServiceListing> findByIdAndTechnicianId(Long id, Long technicianId);
}
