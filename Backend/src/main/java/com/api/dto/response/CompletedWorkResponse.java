package com.api.dto.response;

import java.time.LocalDateTime;

/** Public work history includes customer identity, but no contact details or private notes. */
public record CompletedWorkResponse(Long id, String category, LocalDateTime completedAt,
        Long customerUserId, String customerName) {}
