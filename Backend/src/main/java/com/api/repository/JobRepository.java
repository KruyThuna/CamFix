package com.api.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Repository;

import com.api.entity.Job;

@Repository
public interface JobRepository extends JpaRepository<Job, Long> {

    Page<Job> findByTechnicianIdAndStatus(Long technicianId, String status, Pageable pageable);

    List<Job> findByTechnicianId(Long technicianId);
    boolean existsByCustomerUserId(Long customerUserId);
    boolean existsByTechnicianId(Long technicianId);
<<<<<<< HEAD

    List<Job> findByCustomerUserId(Long customerUserId);
=======
>>>>>>> origin/main

    long countByStatus(String status);

    long countByStatusIn(List<String> statuses);

    /** Real completed-job count for one of a technician's named listings. */
    long countByTechnicianServiceIdAndStatus(Long technicianServiceId, String status);

    /** Real total completed-job count for a technician across every category/listing. */
    long countByTechnicianIdAndStatus(Long technicianId, String status);
}
