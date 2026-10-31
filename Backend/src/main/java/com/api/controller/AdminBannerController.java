package com.api.controller;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import com.api.dto.banner.BannerDtos.BannerResponse;
import com.api.service.AppBannerService;

/**
 * Admin Console endpoints for managing Client App promotional banners.
 */
@RestController
@RequestMapping("/api/admin/banners")
public class AdminBannerController {

    private static final String AUTH = "Authorization";
    private final AppBannerService bannerService;

    public AdminBannerController(AppBannerService bannerService) {
        this.bannerService = bannerService;
    }

    /** List all banners (both active and inactive). */
    @GetMapping
    public List<BannerResponse> listAll(@RequestHeader(value = AUTH, required = false) String auth) {
        return bannerService.listAll(auth);
    }

    /** Seed/restore old default system banners into the database. */
    @PostMapping("/seed")
    public List<BannerResponse> seedDefaults(@RequestHeader(value = AUTH, required = false) String auth) {
        return bannerService.seedDefaultBanners(auth);
    }

    /** Create a new banner with optional image file. */
    @PostMapping(consumes = { "multipart/form-data" })
    public ResponseEntity<BannerResponse> create(
            @RequestHeader(value = AUTH, required = false) String auth,
            @RequestParam("title") String title,
            @RequestParam(value = "subtitle", required = false) String subtitle,
            @RequestParam(value = "category", required = false) String category,
            @RequestParam(value = "actionUrl", required = false) String actionUrl,
            @RequestParam(value = "displayOrder", required = false, defaultValue = "0") Integer displayOrder,
            @RequestParam(value = "active", required = false, defaultValue = "true") Boolean active,
            @RequestParam(value = "file", required = false) MultipartFile file) {
        BannerResponse created = bannerService.create(auth, title, subtitle, category, actionUrl, displayOrder, active, file);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    /** Update an existing banner. */
    @PutMapping(value = "/{id}", consumes = { "multipart/form-data" })
    public BannerResponse update(
            @RequestHeader(value = AUTH, required = false) String auth,
            @PathVariable Long id,
            @RequestParam(value = "title", required = false) String title,
            @RequestParam(value = "subtitle", required = false) String subtitle,
            @RequestParam(value = "category", required = false) String category,
            @RequestParam(value = "actionUrl", required = false) String actionUrl,
            @RequestParam(value = "displayOrder", required = false) Integer displayOrder,
            @RequestParam(value = "active", required = false) Boolean active,
            @RequestParam(value = "file", required = false) MultipartFile file) {
        return bannerService.update(auth, id, title, subtitle, category, actionUrl, displayOrder, active, file);
    }

    /** Delete a banner. */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(
            @RequestHeader(value = AUTH, required = false) String auth,
            @PathVariable Long id) {
        bannerService.delete(auth, id);
        return ResponseEntity.noContent().build();
    }
}
