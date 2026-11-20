package com.api.modules.technician.controller;




import com.api.modules.booking.entity.Job;
import com.api.modules.technician.entity.Technician;
import com.api.modules.admin.entity.Category;
import java.util.List;

import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.api.modules.technician.entity.TechnicianServicePhoto;
import com.api.modules.technician.service.PublicTechnicianService;
import com.api.modules.technician.service.TechnicianServiceManager;
import com.api.modules.technician.dto.PublicTechnicianResponse;
import com.api.modules.technician.dto.CompletedWorkResponse;
import com.api.modules.technician.dto.TechnicianServiceResponse;

/** The customer-facing technician directory - public (no auth), approved
 *  technicians only. See {@link PublicTechnicianService} for the visibility rule. */
@RestController
@RequestMapping("/api/technicians")
public class PublicTechnicianController {

    private final PublicTechnicianService service;
    private final TechnicianServiceManager services;

    public PublicTechnicianController(PublicTechnicianService service, TechnicianServiceManager services) {
        this.service = service;
        this.services = services;
    }

    @GetMapping
    public List<PublicTechnicianResponse> list(@RequestParam(required = false) String category) {
        return service.list(category);
    }

    @GetMapping("/{id}")
    public PublicTechnicianResponse get(@PathVariable Long id) {
        return service.get(id);
    }

    /** A technician's own named/priced service listings, real completed-job
     *  counts included - what the customer app's Achievements tab shows. */
    @GetMapping("/{id}/services")
    public List<TechnicianServiceResponse> listServices(@PathVariable Long id) {
        return services.listPublic(id);
    }

    /** Completed work, newest first, without customer details. */
    @GetMapping("/{id}/completed-work")
    public List<CompletedWorkResponse> completedWork(
            @PathVariable Long id, @RequestParam(defaultValue = "0") int page) {
        return services.completedWork(id, page);
    }

    /** Public photo for one listing (approved technicians only). */
    @GetMapping("/services/{listingId}/photo")
    public ResponseEntity<byte[]> servicePhoto(@PathVariable Long listingId) {
        TechnicianServicePhoto photo = services.publicPhoto(listingId);
        MediaType type;
        try {
            type = MediaType.parseMediaType(photo.getContentType());
        } catch (Exception e) {
            type = MediaType.IMAGE_JPEG;
        }
        return ResponseEntity.ok()
                .contentType(type)
                .header(HttpHeaders.CACHE_CONTROL, "public, max-age=86400")
                .body(photo.getData());
    }
}
