package com.api.Repo;

import com.api.Entity.TechnicianAddresses;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface TechnicianAddressRepository extends JpaRepository<TechnicianAddresses, Long> {

    // Find all addresses belonging to a specific technician
    List<TechnicianAddresses> findByTechnicianId(Long technicianId);

    // Find the default address for a technician
    Optional<TechnicianAddresses> findByTechnicianIdAndIsDefaultTrue(Long technicianId);
}