package com.api.Repo;

import com.api.Entity.TechnicianLiveLocation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface TechnicianLiveLocationRepository extends JpaRepository<TechnicianLiveLocation, Long> {

    // 1. Returns Optional<Entity> for safe null/empty handling
    Optional<TechnicianLiveLocation> findByTechnicianId(Long technicianId);

    // 2. Custom update query with @Modifying and @Query
    @Modifying
    @Query("UPDATE TechnicianLiveLocation t " +
            "SET t.latitude = :latitude, " +
            "    t.longitude = :longitude, " +
            "    t.accuracy = :accuracy, " +
            "    t.lastUpdate = CURRENT_TIMESTAMP " +
            "WHERE t.technicianId = :technicianId")
    int updateLocationByTechnicianId(
            @Param("technicianId") Long technicianId,
            @Param("latitude") Double latitude,
            @Param("longitude") Double longitude,
            @Param("accuracy") Double accuracy);
}