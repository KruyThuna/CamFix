package com.api.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.api.entity.ChatMessage;

@Repository
public interface ChatMessageRepository extends JpaRepository<ChatMessage, Long> {

    List<ChatMessage> findByJobIdOrderByIdAsc(Long jobId);

    List<ChatMessage> findByJobIdAndIdGreaterThanOrderByIdAsc(Long jobId, Long afterId);

    List<ChatMessage> findByJobIdIn(List<Long> jobIds);

    List<ChatMessage> findByJobIdInOrderByIdAsc(List<Long> jobIds);

    List<ChatMessage> findByJobIdInAndIdGreaterThanOrderByIdAsc(List<Long> jobIds, Long afterId);

    /** Unread messages in a thread sent by the *other* side. */
    List<ChatMessage> findByJobIdAndSenderRoleAndReadAtIsNull(Long jobId, String senderRole);

    List<ChatMessage> findByJobIdInAndSenderRoleAndReadAtIsNull(List<Long> jobIds, String senderRole);
}
