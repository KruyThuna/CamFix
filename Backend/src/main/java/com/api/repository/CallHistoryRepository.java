package com.api.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.api.entity.CallHistory;

@Repository
public interface CallHistoryRepository extends JpaRepository<CallHistory, Long> {
    List<CallHistory> findByUser_UserIdOrderByCreatedAtDesc(Long userId);

    List<CallHistory> findByTechnician_TechnicianIdOrderByCreatedAtDesc(Long technicianId);

    Optional<CallHistory> findByCallIdAndUser_UserId(Long callId, Long userId);
}
