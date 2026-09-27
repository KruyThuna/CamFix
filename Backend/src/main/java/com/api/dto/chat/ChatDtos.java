package com.api.dto.chat;

import java.time.LocalDateTime;

/** Request/response shapes for {@code /api/chats}. */
public final class ChatDtos {

    private ChatDtos() {
    }

    /** POST body. */
    public record SendMessageRequest(String body) {
    }

    /** One message; {@code mine} is relative to the caller. */
    public record MessageResponse(
            Long id,
            Long jobId,
            String senderRole,
            boolean mine,
            String body,
            LocalDateTime createdAt,
            LocalDateTime readAt) {
    }

    /** One conversation (= one booking with an assigned technician). */
    public record ThreadResponse(
            Long jobId,
            String category,
            String jobStatus,
            /** CUSTOMER or TECHNICIAN - the caller's side of this job. */
            String myRole,
            String otherName,
            String otherPhone,
            /** Set when the other side is the technician (for their photo). */
            Long otherTechnicianId,
            String lastMessage,
            boolean lastMine,
            LocalDateTime lastAt,
            int unreadCount) {
    }
}
