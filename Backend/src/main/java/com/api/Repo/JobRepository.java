package com.api.Repo;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.api.Entity.Job;

@Repository
public interface JobRepository extends JpaRepository<Job, Long> {

    List<Job> findByTechnicianId(Long technicianId);

    long countByStatus(String status);

    long countByStatusIn(List<String> statuses);
}
