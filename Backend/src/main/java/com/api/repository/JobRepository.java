package com.api.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.api.entity.Job;

@Repository
public interface JobRepository extends JpaRepository<Job, Long> {

    List<Job> findByTechnicianId(Long technicianId);

    List<Job> findByCustomerUserId(Long customerUserId);

    long countByStatus(String status);

    long countByStatusIn(List<String> statuses);
}
