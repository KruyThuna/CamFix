package com.api.Controller;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.api.Service.AdminService;
import com.api.dto.Admin.AdminJobRequest;
import com.api.dto.Admin.AdminJobResponse;
import com.api.dto.Admin.AdminTechnicianRequest;
import com.api.dto.Admin.AdminTechnicianResponse;
import com.api.dto.Admin.DashboardStatsResponse;
import com.api.dto.Admin.TechnicianLocationResponse;

/**
 * Console API consumed by {@code /admin} (the Vite app on :5173). Every handler
 * calls {@link AdminService#requireAdmin(String)} first because the project has
 * no security filter chain - see {@code SwaggerConfig}.
 */
@RestController
@RequestMapping("/api/admin")
public class AdminController {

    private static final String AUTH = "Authorization";

    private final AdminService adminService;

    public AdminController(AdminService adminService) {
        this.adminService = adminService;
    }

    // --- Dashboard --------------------------------------------------------------

    @GetMapping("/stats")
    public DashboardStatsResponse stats(@RequestHeader(value = AUTH, required = false) String auth) {
        adminService.requireAdmin(auth);
        return adminService.stats();
    }

    // --- Technicians ---------------------------------------------------------

    @GetMapping("/technicians")
    public List<AdminTechnicianResponse> listTechnicians(
            @RequestHeader(value = AUTH, required = false) String auth,
            @RequestParam(required = false) String approval,
            @RequestParam(required = false) String account,
            @RequestParam(required = false) String category,
            @RequestParam(required = false) String q) {
        adminService.requireAdmin(auth);
        return adminService.listTechnicians(approval, account, category, q);
    }

    @GetMapping("/technicians/locations")
    public List<TechnicianLocationResponse> technicianLocations(
            @RequestHeader(value = AUTH, required = false) String auth) {
        adminService.requireAdmin(auth);
        return adminService.technicianLocations();
    }

    @GetMapping("/technicians/{id}")
    public AdminTechnicianResponse getTechnician(
            @RequestHeader(value = AUTH, required = false) String auth,
            @PathVariable Long id) {
        adminService.requireAdmin(auth);
        return adminService.getTechnician(id);
    }

    @PostMapping("/technicians")
    public ResponseEntity<AdminTechnicianResponse> createTechnician(
            @RequestHeader(value = AUTH, required = false) String auth,
            @RequestBody AdminTechnicianRequest body) {
        adminService.requireAdmin(auth);
        return ResponseEntity.status(HttpStatus.CREATED).body(adminService.createTechnician(body));
    }

    @PutMapping("/technicians/{id}")
    public AdminTechnicianResponse updateTechnician(
            @RequestHeader(value = AUTH, required = false) String auth,
            @PathVariable Long id,
            @RequestBody AdminTechnicianRequest body) {
        adminService.requireAdmin(auth);
        return adminService.updateTechnician(id, body);
    }

    @DeleteMapping("/technicians/{id}")
    public ResponseEntity<Void> deleteTechnician(
            @RequestHeader(value = AUTH, required = false) String auth,
            @PathVariable Long id) {
        adminService.requireAdmin(auth);
        adminService.deleteTechnician(id);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/technicians/{id}/approve")
    public AdminTechnicianResponse approve(
            @RequestHeader(value = AUTH, required = false) String auth,
            @PathVariable Long id) {
        adminService.requireAdmin(auth);
        return adminService.approveTechnician(id);
    }

    @PostMapping("/technicians/{id}/reject")
    public AdminTechnicianResponse reject(
            @RequestHeader(value = AUTH, required = false) String auth,
            @PathVariable Long id,
            @RequestBody(required = false) ReasonBody body) {
        adminService.requireAdmin(auth);
        return adminService.rejectTechnician(id, body == null ? null : body.reason());
    }

    @PostMapping("/technicians/{id}/suspend")
    public AdminTechnicianResponse suspend(
            @RequestHeader(value = AUTH, required = false) String auth,
            @PathVariable Long id) {
        adminService.requireAdmin(auth);
        return adminService.suspendTechnician(id);
    }

    @PostMapping("/technicians/{id}/reactivate")
    public AdminTechnicianResponse reactivate(
            @RequestHeader(value = AUTH, required = false) String auth,
            @PathVariable Long id) {
        adminService.requireAdmin(auth);
        return adminService.reactivateTechnician(id);
    }

    // --- Jobs ------------------------------------------------------------------

    @GetMapping("/jobs")
    public List<AdminJobResponse> listJobs(
            @RequestHeader(value = AUTH, required = false) String auth,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) Long technicianId,
            @RequestParam(required = false) String q) {
        adminService.requireAdmin(auth);
        return adminService.listJobs(status, technicianId, q);
    }

    @GetMapping("/jobs/{id}")
    public AdminJobResponse getJob(
            @RequestHeader(value = AUTH, required = false) String auth,
            @PathVariable Long id) {
        adminService.requireAdmin(auth);
        return adminService.getJob(id);
    }

    @PostMapping("/jobs")
    public ResponseEntity<AdminJobResponse> createJob(
            @RequestHeader(value = AUTH, required = false) String auth,
            @RequestBody AdminJobRequest body) {
        adminService.requireAdmin(auth);
        return ResponseEntity.status(HttpStatus.CREATED).body(adminService.createJob(body));
    }

    @PutMapping("/jobs/{id}")
    public AdminJobResponse updateJob(
            @RequestHeader(value = AUTH, required = false) String auth,
            @PathVariable Long id,
            @RequestBody AdminJobRequest body) {
        adminService.requireAdmin(auth);
        return adminService.updateJob(id, body);
    }

    @PostMapping("/jobs/{id}/assign")
    public AdminJobResponse assignJob(
            @RequestHeader(value = AUTH, required = false) String auth,
            @PathVariable Long id,
            @RequestBody(required = false) AssignBody body) {
        adminService.requireAdmin(auth);
        return adminService.assignJob(id, body == null ? null : body.technicianId());
    }

    @PostMapping("/jobs/{id}/status")
    public AdminJobResponse changeJobStatus(
            @RequestHeader(value = AUTH, required = false) String auth,
            @PathVariable Long id,
            @RequestBody(required = false) StatusBody body) {
        adminService.requireAdmin(auth);
        return adminService.changeJobStatus(id, body == null ? null : body.status());
    }

    @PostMapping("/jobs/{id}/cancel")
    public AdminJobResponse cancelJob(
            @RequestHeader(value = AUTH, required = false) String auth,
            @PathVariable Long id) {
        adminService.requireAdmin(auth);
        return adminService.cancelJob(id);
    }

    // --- Small request bodies ------------------------------------------------

    public record ReasonBody(String reason) {
    }

    public record AssignBody(Long technicianId) {
    }

    public record StatusBody(String status) {
    }
}
