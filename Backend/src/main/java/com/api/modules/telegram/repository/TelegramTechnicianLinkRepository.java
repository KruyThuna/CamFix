package com.api.modules.telegram.repository;

import com.api.modules.telegram.entity.TelegramTechnicianLink;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TelegramTechnicianLinkRepository extends JpaRepository<TelegramTechnicianLink, Long> {
    Optional<TelegramTechnicianLink> findByTechnicianId(Long technicianId);
    Optional<TelegramTechnicianLink> findByChatId(String chatId);
}
