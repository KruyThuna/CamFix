package com.api.Service.implement;

import java.util.List;
import java.util.Optional;

import org.springframework.stereotype.Service;
import com.api.Entity.Technician;
import com.api.Repo.TechnicianRepository;
import com.api.Service.TechnicianService;

import lombok.Data;

@Data
@Service
public class TechnicianServiceImpl implements TechnicianService {

    private final TechnicianRepository technicianRepository; // ← type is the repository

    @Override
    public Technician creatTechnician(Technician technician) {
        return technicianRepository.save(technician);
    }

    @Override
    public List<Technician> getAllTechnician() {
        return technicianRepository.findAll();
    }

    @Override
    public Optional<Technician> findBytechnician_id(Long technician_id) {
        return technicianRepository.findById(technician_id);
    }

    @Override
    public Technician updateById(Long technician_id, Technician technician) {
        Technician tech = technicianRepository.findById(technician_id)
                .orElseThrow(() -> new RuntimeException("Technician not found with id: " + technician_id));
        // Update the existing technician with the new values

        return technicianRepository.save(tech);
    }

    @Override
    public void DeleteTechnician(Long technician_id) {
        technicianRepository.deleteById(technician_id);
    }

    @Override
    public Technician getTechnicianById(Long technician_id) {
        return technicianRepository.findById(technician_id)
                .orElseThrow(() -> new RuntimeException("Technician not found with id: " + technician_id));
    }
}