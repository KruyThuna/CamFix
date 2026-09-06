package com.api.Controller;

import java.util.List;

import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.api.Entity.Technician;
import com.api.Service.TechnicianService;

import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;

@RestController
@RequestMapping("/api/technician")
public class TechnicianController {

    public final TechnicianService technicianService;

    public TechnicianController(TechnicianService technicianService) {
        this.technicianService = technicianService;
    }

    @GetMapping
    public List<Technician> getAllTechnician() {
        return technicianService.getAllTechnician();
    }

    @PostMapping("technician/{id}")
    public Technician getTechnicianById(@RequestBody Long technician_id) {
        return technicianService.getTechnicianById(technician_id);
    }

    @RequestMapping(value = "/updateTechnician/{id}", method = RequestMethod.PUT)
    public Technician updateTechnician(@RequestParam Long technician_id, @RequestBody Technician technician) {

        return technicianService.getTechnicianById(technician_id);
    }

    @DeleteMapping("/deleteTechnician/{id}")
    public void deleteTechnician(@RequestParam Long technician_id, @RequestBody Long technician) {
        technicianService.DeleteTechnician(technician_id);
    }

}
