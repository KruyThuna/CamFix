package com.api.modules.review.controller;


import com.api.modules.review.entity.Review;
import java.util.List;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.api.modules.review.service.FavoriteService;
import com.api.modules.review.dto.FavoriteRequest;
import com.api.modules.review.dto.FavoriteResponse;

/** The signed-in customer's saved technicians (`/api/favorites/**`). */
@RestController
@RequestMapping("/api/favorites")
public class FavoriteController {

    private static final String AUTH = "Authorization";

    private final FavoriteService favoriteService;

    public FavoriteController(FavoriteService favoriteService) {
        this.favoriteService = favoriteService;
    }

    @GetMapping("/mine")
    public List<FavoriteResponse> mine(@RequestHeader(value = AUTH, required = false) String auth) {
        return favoriteService.mine(auth);
    }

    @PostMapping
    public ResponseEntity<FavoriteResponse> add(
            @RequestHeader(value = AUTH, required = false) String auth,
            @RequestBody FavoriteRequest body) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(favoriteService.add(auth, body == null ? null : body.getTechnicianId()));
    }

    @DeleteMapping("/{technicianId}")
    public ResponseEntity<Void> remove(
            @RequestHeader(value = AUTH, required = false) String auth,
            @PathVariable Long technicianId) {
        favoriteService.remove(auth, technicianId);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/{technicianId}/check")
    public Map<String, Boolean> check(
            @RequestHeader(value = AUTH, required = false) String auth,
            @PathVariable Long technicianId) {
        return Map.of("isFavorite", favoriteService.isFavorite(auth, technicianId));
    }
}
