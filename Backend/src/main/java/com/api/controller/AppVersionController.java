package com.api.controller;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.util.LinkedHashMap;
import java.util.Map;

import org.springframework.core.io.InputStreamResource;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * In-app update API.
 * Mobile clients query /api/app/version on startup to determine if a new APK has
 * been released, and can download it directly from /api/app/download.
 */
@RestController
@RequestMapping("/api/app")
public class AppVersionController {

    public static final String LATEST_VERSION = "1.3.2";
    public static final int LATEST_BUILD_NUMBER = 22;
    public static final int MIN_SUPPORTED_BUILD = 1;

    @GetMapping("/version")
    public ResponseEntity<Map<String, Object>> getVersion() {
        Map<String, Object> res = new LinkedHashMap<>();
        res.put("version", LATEST_VERSION);
        res.put("buildNumber", LATEST_BUILD_NUMBER);
        res.put("minSupportedBuild", MIN_SUPPORTED_BUILD);
        res.put("downloadUrl", "https://api.camapp.store/api/app/download");
        res.put("fileSizeMb", getApkSizeMb());
        res.put("forceUpdate", false);
        res.put("releaseNotesKm", "• កែលម្អផ្ទាំងទូទាត់ប្រាក់ KHQR Bakong Standee ផ្លូវការ\n• បន្ថែមផ្ទាំងជ្រើសរើសវិធីសាស្ត្រទូទាត់ និងគណនីដែលបានភ្ជាប់ (Bound Asset)\n• បង្ហាញកំណត់ត្រាប្រតិបត្តិការផ្ទាល់ (Live Service Progress SLA)");
        res.put("releaseNotesEn", "• Official NBC Bakong KHQR Standee payment UI\n• Bound asset quick selector and payment options modal\n• Real-time Live Service Progress operational log with STANDARD SLA");
        return ResponseEntity.ok(res);
    }

    @GetMapping("/download")
    public ResponseEntity<Resource> downloadApk() throws IOException {
        File file = resolveApkFile();
        if (file == null || !file.exists()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }

        InputStreamResource resource = new InputStreamResource(new FileInputStream(file));
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"Camfix_Latest.apk\"")
                .header(HttpHeaders.CACHE_CONTROL, "no-cache, no-store, must-revalidate")
                .contentType(MediaType.parseMediaType("application/vnd.android.package-archive"))
                .contentLength(file.length())
                .body(resource);
    }

    private File resolveApkFile() {
        File[] candidates = new File[] {
            new File("/app/Camfix_Latest.apk"),
            new File("Camfix_Latest.apk"),
            new File("../Camfix_Latest.apk"),
            new File("c:/CamV4/CamFix/Camfix_Latest.apk"),
            new File("Camfix_App/build/app/outputs/flutter-apk/app-release.apk")
        };
        for (File candidate : candidates) {
            if (candidate.exists() && candidate.isFile()) {
                return candidate;
            }
        }
        return null;
    }

    private double getApkSizeMb() {
        File f = resolveApkFile();
        if (f != null && f.exists()) {
            return Math.round((f.length() / (1024.0 * 1024.0)) * 10.0) / 10.0;
        }
        return 61.4;
    }
}

