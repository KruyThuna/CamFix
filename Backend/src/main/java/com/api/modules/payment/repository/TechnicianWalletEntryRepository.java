package com.api.modules.payment.repository;

import com.api.modules.payment.entity.TechnicianWalletEntry;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface TechnicianWalletEntryRepository extends JpaRepository<TechnicianWalletEntry, Long> {
    boolean existsByPaymentId(Long paymentId);
    @Query("select coalesce(sum(e.amount), 0) from TechnicianWalletEntry e where e.technicianId = :technicianId")
    Double balance(@Param("technicianId") Long technicianId);
    Optional<TechnicianWalletEntry> findFirstByTechnicianIdOrderByCreatedAtDesc(Long technicianId);
}
