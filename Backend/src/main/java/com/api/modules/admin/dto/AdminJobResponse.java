package com.api.modules.admin.dto;




import com.api.modules.booking.entity.Job;
import com.api.modules.technician.entity.Technician;
import com.api.modules.admin.entity.Category;
import lombok.Getter;
import lombok.Setter;

/** Console-facing view of a job, with the assigned technician's name/phone resolved. */
@Getter
@Setter
public class AdminJobResponse {

    private Long id;
    private String customerName;
    private String customerPhone;
    private Long customerUserId;
    private String category;
    private String description;
    private String address;
    private Double lat;
    private Double lng;
    private String status;
    private Long technicianId;
    private String technicianName;
    private String technicianPhone;
    private String createdAt;
    private String scheduledAt;
    private String assignedAt;
    private String completedAt;
    private String notes;
    private String photoUrl;
}
