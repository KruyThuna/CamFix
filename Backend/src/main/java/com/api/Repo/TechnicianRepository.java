package com.api.Repo;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.api.Entity.Technician;

@Repository
public interface TechnicianRepository extends JpaRepository<Technician, Long> {

}
