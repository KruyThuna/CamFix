package com.api.Service;

import com.api.Entity.Technician;
import java.util.List;
import java.util.Optional;

public interface TechnicianService {

    Technician creatTechnician(Technician technician);

    List<Technician> getAllTechnician();

    Optional<Technician> findBytechnician_id(Long technician_id);

    Technician getTechnicianById(Long technician_id);

    Technician updateById(Long technician_id, Technician technician);

    // Technician updateTechnician(Long technician_id, Technician technician);
    void DeleteTechnician(Long technician_id);

}