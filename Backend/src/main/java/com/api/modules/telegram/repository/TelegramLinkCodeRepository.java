package com.api.modules.telegram.repository;

import com.api.modules.telegram.entity.TelegramLinkCode;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TelegramLinkCodeRepository extends JpaRepository<TelegramLinkCode, String> { }
