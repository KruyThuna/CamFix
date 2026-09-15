package com.api.Repo;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.api.Entity.ServiceQuote;

@Repository
public interface ServiceQuoteRepository extends JpaRepository<ServiceQuote, Long> {

    List<ServiceQuote> findByJobIdOrderByVersionDesc(Long jobId);

    Optional<ServiceQuote> findByJobIdAndStatus(Long jobId, String status);

    Optional<ServiceQuote> findTopByJobIdOrderByVersionDesc(Long jobId);

    boolean existsByJobIdAndStatus(Long jobId, String status);
}
