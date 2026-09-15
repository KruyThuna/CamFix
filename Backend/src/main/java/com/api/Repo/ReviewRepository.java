package com.api.Repo;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.api.Entity.Review;

@Repository
public interface ReviewRepository extends JpaRepository<Review, Long> {

    Optional<Review> findByJobId(Long jobId);

    boolean existsByJobId(Long jobId);

    List<Review> findByTechnicianIdOrderByCreatedAtDesc(Long technicianId);

    long countByTechnicianId(Long technicianId);
}
