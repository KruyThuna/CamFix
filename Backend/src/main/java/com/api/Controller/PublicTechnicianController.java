package com.api.Controller;

import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.api.Service.PublicTechnicianService;
import com.api.dto.Response.PublicTechnicianResponse;

/** The customer-facing technician directory - public (no auth), approved
 *  technicians only. See {@link PublicTechnicianService} for the visibility rule. */
@RestController
@RequestMapping("/api/technicians")
public class PublicTechnicianController {

    private final PublicTechnicianService service;

    public PublicTechnicianController(PublicTechnicianService service) {
        this.service = service;
    }

    @GetMapping
    public List<PublicTechnicianResponse> list(@RequestParam(required = false) String category) {
        return service.list(category);
    }

    @GetMapping("/{id}")
    public PublicTechnicianResponse get(@PathVariable Long id) {
        return service.get(id);
    }
}
