package com.api.Repo;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import com.api.Entity.CallHistory;

@Repository
public interface CallHistoryRepository extends JpaRepository<CallHistory, Long> {
    List<CallHistory> findByUser_UserId(Long userId);

    List<CallHistory> findByTechnician_TechnicianId(Long technicianId);
}