package com.api.dto.banner;

import java.time.LocalDateTime;

public final class BannerDtos {

    private BannerDtos() {
    }

    public record BannerResponse(
            Long id,
            String title,
            String subtitle,
            String category,
            String actionUrl,
            String imageUrl,
            int displayOrder,
            boolean active,
            LocalDateTime createdAt,
            LocalDateTime updatedAt
    ) {
    }
}
