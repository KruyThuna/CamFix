package com.api.dto.Request;

import com.api.Entity.Technician;
import com.api.Entity.Users;

public class FavoriteRequest {
    private Users users;
    private Technician technician;

    public FavoriteRequest(Users users, Technician technician) {
        this.users = users;
        this.technician = technician;
    }

    public Users getUsers() {
        return users;
    }

    public Technician getTechnician() {
        return technician;
    }

    public void setUsers(Users users) {
        this.users = users;
    }

    public void setTechnician(Technician technician) {
        this.technician = technician;
    }

}
