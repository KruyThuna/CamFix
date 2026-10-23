package com.api.controller;

import java.util.List;

import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.api.entity.Technician;
import com.api.service.TechnicianService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;

@Tag(name = "Technician CRUD", description = "Technician registration, profile management, and CRUD operations")
@RestController
@RequestMapping("/api/technician")
public class TechnicianController {

    public final TechnicianService technicianService;

    public TechnicianController(TechnicianService technicianService) {
        this.technicianService = technicianService;
    }

    @Operation(summary = "Get all technicians", description = "Read/list all technicians in the system", tags = {"Read", "Technician CRUD"})
    @GetMapping
    public List<Technician> getAllTechnician() {
        return technicianService.getAllTechnician();
    }

    @Operation(summary = "Get technician by ID", description = "Read/query technician details by ID", tags = {"Read", "Technician CRUD"})
    @PostMapping("technician/{id}")
    public Technician getTechnicianById(@RequestBody Long technician_id) {
        return technicianService.getTechnicianById(technician_id);
    }

    @Operation(summary = "Update technician", description = "Update existing technician profile details", tags = {"Update", "Technician CRUD"})
    @RequestMapping(value = "/updateTechnician/{id}", method = RequestMethod.PUT)
    public Technician updateTechnician(@RequestParam Long technician_id, @RequestBody Technician technician) {
        return technicianService.getTechnicianById(technician_id);
    }

    @Operation(summary = "Delete technician", description = "Delete a technician by ID", tags = {"Delete", "Technician CRUD"})
    @DeleteMapping("/deleteTechnician/{id}")
    public void deleteTechnician(@RequestParam Long technician_id, @RequestBody Long technician) {
        technicianService.DeleteTechnician(technician_id);
    }
}