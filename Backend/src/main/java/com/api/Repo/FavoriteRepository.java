package com.api.Repo;

import com.api.Entity.Favorite;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Repository
public interface FavoriteRepository extends JpaRepository<Favorite, Long> {

    List<Favorite> findByUser_UserId(Long userId);

    Page<Favorite> findByUser_UserId(Long userId, Pageable pageable);

    Optional<Favorite> findByUser_UserIdAndTechnician_TechnicianId(Long userId, Long technicianId);

    boolean existsByUser_UserIdAndTechnician_TechnicianId(Long userId, Long technicianId);

    long countByTechnician_TechnicianId(Long technicianId);

    @Transactional
    void deleteByUser_UserIdAndTechnician_TechnicianId(Long userId, Long technicianId);

    @Modifying
    @Transactional
    @Query("DELETE FROM Favorite f WHERE f.user.userId = :userId AND f.technician.technicianId = :technicianId")
    void deleteByUserAndTechnician(@Param("userId") Long userId, @Param("technicianId") Long technicianId);

    // FIXED: Removed invalid "JOIN FETCH t.user"
    @Query("SELECT f FROM Favorite f " +
            "JOIN FETCH f.technician t " +
            "WHERE f.user.userId = :userId")
    List<Favorite> findAllWithTechnicianDetailsByUserId(@Param("userId") Long userId);
}