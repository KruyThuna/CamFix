package com.api.Repo;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.api.Entity.Payment;

@Repository
public interface PaymentRepository extends JpaRepository<Payment, Long> {

    Optional<Payment> findByQuoteId(Long quoteId);

    List<Payment> findByJobIdIn(List<Long> jobIds);

    Optional<Payment> findFirstByJobIdOrderByIdDesc(Long jobId);
}
