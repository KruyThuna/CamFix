package com.api.service;

import java.io.IOException;
import java.io.InputStream;
import java.util.List;
import java.util.NoSuchElementException;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import com.api.dto.banner.BannerDtos.BannerResponse;
import com.api.entity.AppBanner;
import com.api.repository.AppBannerRepository;

@Service
public class AppBannerService {

    private static final long MAX_IMAGE_BYTES = 10L * 1024 * 1024; // 10MB
    private final AppBannerRepository bannerRepository;
    private final AdminService adminService;

    public AppBannerService(AppBannerRepository bannerRepository, AdminService adminService) {
        this.bannerRepository = bannerRepository;
        this.adminService = adminService;
    }

    /** Public: list all active banners for the client app. Auto-seeds default banners if empty. */
    @Transactional
    public List<BannerResponse> listActive() {
        if (bannerRepository.count() == 0) {
            seedDefaultBanners(null);
        }
        return bannerRepository.findByActiveTrueOrderByDisplayOrderAscIdDesc().stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    /** Admin: list all banners (active & inactive). Auto-seeds default banners if empty. */
    @Transactional
    public List<BannerResponse> listAll(String authorization) {
        adminService.requireAdmin(authorization);
        if (bannerRepository.count() == 0) {
            seedDefaultBanners(null);
        }
        return bannerRepository.findAllByOrderByDisplayOrderAscIdDesc().stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    /** Public: retrieve raw banner image bytes and content type. */
    @Transactional(readOnly = true)
    public AppBanner getImage(Long id) {
        AppBanner b = bannerRepository.findById(id)
                .orElseThrow(() -> new NoSuchElementException("Banner not found: " + id));
        if (b.getImage() == null || b.getImage().length == 0) {
            throw new NoSuchElementException("Banner image not set: " + id);
        }
        return b;
    }

    /** Seeds the old/default client app banners into the database so Admin can edit them. */
    @Transactional
    public List<BannerResponse> seedDefaultBanners(String authorization) {
        if (authorization != null) {
            adminService.requireAdmin(authorization);
        }
        if (bannerRepository.count() > 0) {
            return bannerRepository.findAllByOrderByDisplayOrderAscIdDesc().stream()
                    .map(this::toDto)
                    .collect(Collectors.toList());
        }

        byte[] acImage = null;
        try (InputStream is = getClass().getResourceAsStream("/default_banner_ac.png")) {
            if (is != null) {
                acImage = is.readAllBytes();
            }
        } catch (Exception ignored) {
        }

        AppBanner b1 = new AppBanner();
        b1.setTitle("Cool Comfort, Fast Service");
        b1.setSubtitle("Certified Air Conditioner repair & maintenance");
        b1.setCategory("Air Conditioner");
        b1.setDisplayOrder(1);
        b1.setActive(true);
        if (acImage != null && acImage.length > 0) {
            b1.setImage(acImage);
            b1.setImageContentType("image/png");
        }
        bannerRepository.save(b1);

        AppBanner b2 = new AppBanner();
        b2.setTitle("On-Demand Home Services, Anytime");
        b2.setSubtitle("Find trusted local technicians near you");
        b2.setCategory(null);
        b2.setDisplayOrder(2);
        b2.setActive(true);
        bannerRepository.save(b2);

        AppBanner b3 = new AppBanner();
        b3.setTitle("Quick & Easy Booking");
        b3.setSubtitle("Transparent quotes and live tracking");
        b3.setCategory(null);
        b3.setDisplayOrder(3);
        b3.setActive(true);
        bannerRepository.save(b3);

        return bannerRepository.findAllByOrderByDisplayOrderAscIdDesc().stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    /** Admin: create a new promotional banner. */
    @Transactional
    public BannerResponse create(
            String authorization,
            String title,
            String subtitle,
            String category,
            String actionUrl,
            Integer displayOrder,
            Boolean active,
            MultipartFile file) {
        adminService.requireAdmin(authorization);
        if (title == null || title.trim().isEmpty()) {
            throw new IllegalArgumentException("Title is required");
        }

        AppBanner b = new AppBanner();
        b.setTitle(title.trim());
        b.setSubtitle(subtitle != null && !subtitle.trim().isEmpty() ? subtitle.trim() : null);
        b.setCategory(category != null && !category.trim().isEmpty() ? category.trim() : null);
        b.setActionUrl(actionUrl != null && !actionUrl.trim().isEmpty() ? actionUrl.trim() : null);
        b.setDisplayOrder(displayOrder != null ? displayOrder : 0);
        b.setActive(active != null ? active : true);

        if (file != null && !file.isEmpty()) {
            validateImage(file);
            try {
                b.setImage(file.getBytes());
                b.setImageContentType(file.getContentType());
            } catch (IOException e) {
                throw new IllegalArgumentException("Failed to read banner image");
            }
        }

        b = bannerRepository.save(b);
        return toDto(b);
    }

    /** Admin: update an existing promotional banner. */
    @Transactional
    public BannerResponse update(
            String authorization,
            Long id,
            String title,
            String subtitle,
            String category,
            String actionUrl,
            Integer displayOrder,
            Boolean active,
            MultipartFile file) {
        adminService.requireAdmin(authorization);
        AppBanner b = bannerRepository.findById(id)
                .orElseThrow(() -> new NoSuchElementException("Banner not found: " + id));

        if (title != null && !title.trim().isEmpty()) {
            b.setTitle(title.trim());
        }
        if (subtitle != null) {
            b.setSubtitle(subtitle.trim().isEmpty() ? null : subtitle.trim());
        }
        if (category != null) {
            b.setCategory(category.trim().isEmpty() ? null : category.trim());
        }
        if (actionUrl != null) {
            b.setActionUrl(actionUrl.trim().isEmpty() ? null : actionUrl.trim());
        }
        if (displayOrder != null) {
            b.setDisplayOrder(displayOrder);
        }
        if (active != null) {
            b.setActive(active);
        }

        if (file != null && !file.isEmpty()) {
            validateImage(file);
            try {
                b.setImage(file.getBytes());
                b.setImageContentType(file.getContentType());
            } catch (IOException e) {
                throw new IllegalArgumentException("Failed to read banner image");
            }
        }

        b = bannerRepository.save(b);
        return toDto(b);
    }

    /** Admin: delete a banner. */
    @Transactional
    public void delete(String authorization, Long id) {
        adminService.requireAdmin(authorization);
        if (!bannerRepository.existsById(id)) {
            throw new NoSuchElementException("Banner not found: " + id);
        }
        bannerRepository.deleteById(id);
    }

    private void validateImage(MultipartFile file) {
        if (file.getSize() > MAX_IMAGE_BYTES) {
            throw new IllegalArgumentException("Banner image must be 10MB or smaller");
        }
        String contentType = file.getContentType();
        if (contentType == null || !contentType.startsWith("image/")) {
            throw new IllegalArgumentException("File must be an image (jpg, png, webp)");
        }
    }

    private BannerResponse toDto(AppBanner b) {
        String imageUrl = (b.getImage() != null && b.getImage().length > 0)
                ? "/api/banners/" + b.getId() + "/image"
                : null;
        return new BannerResponse(
                b.getId(),
                b.getTitle(),
                b.getSubtitle(),
                b.getCategory(),
                b.getActionUrl(),
                imageUrl,
                b.getDisplayOrder() != null ? b.getDisplayOrder() : 0,
                b.isActive(),
                b.getCreatedAt(),
                b.getUpdatedAt());
    }
}
