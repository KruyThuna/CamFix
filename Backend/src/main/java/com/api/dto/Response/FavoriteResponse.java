package com.api.dto.Response;

import java.time.LocalDateTime;

import com.api.Entity.Technician;
import com.api.Entity.Users;

public class FavoriteResponse {

    private Long favoriteId;
    private Users users;
    private Technician technician;
    private LocalDateTime createAt;

    public FavoriteResponse(Long favoriteId, Users users, Technician technician, LocalDateTime createAt) {
        this.favoriteId = favoriteId;
        this.users = users;
        this.technician = technician;
        this.createAt = createAt;
    }

    public Long getFavoriteId() {
        return favoriteId;
    }

    public Users getUsers() {
        return users;
    }

    public Technician getTechnician() {
        return technician;
    }

    public LocalDateTime getCreateAt() {
        return createAt;
    }

    public void setFavoriteId(Long favoriteId) {
        this.favoriteId = favoriteId;
    }

    public void setUsers(Users users) {
        this.users = users;
    }

    public void setTechnician(Technician technician) {
        this.technician = technician;
    }

    public void setCreateAt(LocalDateTime createAt) {
        this.createAt = createAt;
    }

}
