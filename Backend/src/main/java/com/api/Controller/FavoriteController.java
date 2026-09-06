package com.api.Controller;

import com.api.Entity.Favorite;
import com.api.Service.FavoriteService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/favorites")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class FavoriteController {

    private final FavoriteService favoriteService;

    // 1. Get all favorite technicians for a specific user
    @GetMapping("/user/{userId}")
    public ResponseEntity<List<Favorite>> getUserFavorites(@PathVariable Long userId) {
        List<Favorite> favorites = favoriteService.getFavoritesByUser(userId);
        return ResponseEntity.ok(favorites);
    }

    // 2. Check if a technician is favorited by a user
    // @GetMapping("/check")
    // public ResponseEntity<Boolean> isFavorite(
    // @RequestParam Long userId,
    // @RequestParam Long technicianId) {
    // boolean isFav = favoriteService(userId, technicianId);
    // return ResponseEntity.ok(isFav);
    // }

    // 3. Add a technician to favorites
    @PostMapping
    public ResponseEntity<Favorite> addFavorite(
            @RequestParam Long userId,
            @RequestParam Long technicianId) {
        Favorite createdFavorite = favoriteService.addFavorite(userId, technicianId);
        return ResponseEntity.status(HttpStatus.CREATED).body(createdFavorite);
    }

    // 4. Remove a technician from favorites
    @DeleteMapping
    public ResponseEntity<Void> removeFavorite(
            @RequestParam Long userId,
            @RequestParam Long technicianId) {
        favoriteService.removeFavorite(userId, technicianId);
        return ResponseEntity.noContent().build();
    }
}