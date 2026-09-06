package com.api.Service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.api.Entity.Favorite;
import com.api.Entity.Technician;
import com.api.Entity.Users;
import com.api.Repo.FavoriteRepository;
import com.api.Repo.TechnicianRepository;
import com.api.Repo.UserRepository;

import java.util.List;

@Service
@RequiredArgsConstructor
public class FavoriteService {

    private final FavoriteRepository favoriteRepository;
    private final UserRepository userRepository;
    private final TechnicianRepository technicianRepository;

    @Transactional(readOnly = true)
    public List<Favorite> getFavoritesByUser(Long userId) {
        return favoriteRepository.findByUser_UserId(userId);
    }

    @Transactional
    public Favorite addFavorite(Long userId, Long technicianId) {
        if (favoriteRepository.existsByUser_UserIdAndTechnician_TechnicianId(userId, technicianId)) {
            throw new IllegalStateException("Technician already in favorites.");
        }

        Users users = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found: " + userId));
        Technician technician = technicianRepository.findById(technicianId)
                .orElseThrow(() -> new IllegalArgumentException("Technician not found: " + technicianId));

        Favorite favorite = new Favorite();
        favorite.setUser(users);
        favorite.setTechnician(technician);

        return favoriteRepository.save(favorite);
    }

    @Transactional
    public void removeFavorite(Long userId, Long technicianId) {
        favoriteRepository.deleteByUser_UserIdAndTechnician_TechnicianId(userId, technicianId);
    }

    @Transactional(readOnly = true)
    public boolean isFavorite(Long userId, Long technicianId) {
        return favoriteRepository.existsByUser_UserIdAndTechnician_TechnicianId(userId, technicianId);
    }
}