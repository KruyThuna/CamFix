package com.api.Repo;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.api.Entity.Job;

@Repository
public interface JobRepository extends JpaRepository<Job, Long> {

    List<Job> findByTechnicianId(Long technicianId);
    boolean existsByCustomerUserId(Long customerUserId);
    boolean existsByTechnicianId(Long technicianId);

    long countByStatus(String status);

    long countByStatusIn(List<String> statuses);

    /** Real completed-job count for one of a technician's named listings. */
    long countByTechnicianServiceIdAndStatus(Long technicianServiceId, String status);

    /** Real total completed-job count for a technician across every category/listing. */
    long countByTechnicianIdAndStatus(Long technicianId, String status);
}
