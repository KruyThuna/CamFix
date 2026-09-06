package com.api.Entity;

import java.security.Timestamp;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;

@Entity
@Table(name = "reviews")
public class Reviews {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long reviewId;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id", nullable = false)
    private Users users;

    @JoinColumn(name = "technician_id")
    @Column(name = "technicianId")
    private Long technicianId;

    @Column(name = "rating")
    private String rating;

    @Column(name = "command")
    private String command;

    @Column(name = "create_at")
    private Timestamp create_at;

    @Column(name = "update_at")
    private Timestamp update_at;

    public Reviews(Long reviewId,
            Users users, Long techincianId,
            String rating, String command,
            Timestamp create_at, Timestamp update_at) {
        this.reviewId = reviewId;
        this.users = users;
        this.technicianId = techincianId;
        this.rating = rating;
        this.command = command;
        this.create_at = create_at;
        this.update_at = update_at;

    }

    public Long getreviewId() {
        return reviewId;
    }

    public Users getusers() {
        return users;
    }

    public Long gettechnicinaId() {
        return technicianId;
    }

    public String getrating() {
        return rating;
    }

    public String getcommand() {
        return command;
    }

    public Timestamp getcreateAt() {
        return create_at;
    }

    public Timestamp getupdateAt() {
        return update_at;
    }

    public void setreviewId(long reviewId) {
        this.reviewId = reviewId;
    }

    public void setusers(Users users) {
        this.users = users;
    }

    public void settechnicianId(Long technicianId) {
        this.technicianId = technicianId;
    }

    public void setrating(String rating) {
        this.rating = rating;
    }

    public void setcommand(String command) {
        this.command = command;
    }

    public void setcreateAt(Timestamp create_at) {
        this.create_at = create_at;
    }

    public void setupdateAt(Timestamp update_at) {
        this.update_at = update_at;
    }
}
