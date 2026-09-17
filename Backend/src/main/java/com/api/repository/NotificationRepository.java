package com.api.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.api.entity.Notification;

@Repository
public interface NotificationRepository extends JpaRepository<Notification, Long> {

    List<Notification> findByUserUserId(Long userId);

    List<Notification> findByUser_UserIdOrderByCreatedAtDesc(Long userId);

    long countByUser_UserIdAndIsReadFalse(Long userId);

    List<Notification> findByUser_UserIdAndIsReadFalse(Long userId);
}
