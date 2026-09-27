package com.api.Repo;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.api.Entity.KhqrPayment;

@Repository
public interface KhqrPaymentRepository extends JpaRepository<KhqrPayment, Long> {

    Optional<KhqrPayment> findByMd5AndJobId(String md5, Long jobId);
}
