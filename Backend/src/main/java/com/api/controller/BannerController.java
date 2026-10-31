package com.api.controller;

import java.util.List;

import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.api.dto.banner.BannerDtos.BannerResponse;
import com.api.entity.AppBanner;
import com.api.service.AppBannerService;

/**
 * Public endpoints for client applications (Camfix_App) to retrieve promotional
 * hero banners for the Home/Dashboard carousel.
 */
@RestController
@RequestMapping("/api/banners")
public class BannerController {

    private final AppBannerService bannerService;

    public BannerController(AppBannerService bannerService) {
        this.bannerService = bannerService;
    }

    /** Returns active banners sorted by display order. */
    @GetMapping
    public List<BannerResponse> listActive() {
        return bannerService.listActive();
    }

    /** Returns raw image bytes for a banner. */
    @GetMapping("/{id}/image")
    public ResponseEntity<byte[]> image(@PathVariable Long id) {
        AppBanner b = bannerService.getImage(id);
        MediaType type = MediaType.IMAGE_JPEG;
        if (b.getImageContentType() != null) {
            try {
                type = MediaType.parseMediaType(b.getImageContentType());
            } catch (Exception ignored) {
            }
        }
        return ResponseEntity.ok()
                .header(HttpHeaders.CACHE_CONTROL, "public, max-age=3600")
                .contentType(type)
                .body(b.getImage());
    }
}

