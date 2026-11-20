package com.api.modules.technician.dto;



import com.api.modules.technician.entity.Technician;
import com.api.modules.admin.entity.Category;
import java.time.LocalDateTime;

/** Public work history includes customer identity, but no contact details or private notes. */
public record CompletedWorkResponse(Long id, String category, LocalDateTime completedAt,
        Long customerUserId, String customerName) {}
