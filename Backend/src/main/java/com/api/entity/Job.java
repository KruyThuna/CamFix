package com.api.entity;

import java.time.LocalDateTime;

import org.hibernate.annotations.CreationTimestamp;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/**
 * A dispatchable service job managed from the admin console. Kept deliberately
 * flat - the customer and technician are referenced by id only (no JPA
 * relations) so this table can be added without touching the existing
 * {@code users}/{@code technician} mappings.
 */
@Entity
@Table(name = "job")
public class Job {
    public static Builder builder(){return new Builder();}
    public static class Builder { private final Job j=new Job(); public Builder id(Long v){j.id=v;return this;} public Builder category(String v){j.category=v;return this;} public Builder completedAt(LocalDateTime v){j.completedAt=v;return this;} public Builder customerUserId(Long v){j.customerUserId=v;return this;} public Builder customerName(String v){j.customerName=v;return this;} public Builder description(String v){j.description=v;return this;} public Job build(){return j;} }

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "customer_name", nullable = false)
    private String customerName;

    @Column(name = "customer_phone", nullable = false)
    private String customerPhone;

    /** {@code users.Userid} of the customer, when the job came from a known account. */
    @Column(name = "customer_user_id")
    private Long customerUserId;

    @Column(nullable = false)
    private String category;

    @Column(nullable = false, length = 2000)
    private String description;

    private String address;

    private Double lat;

    private Double lng;

    /** REQUESTED | ASSIGNED | ON_THE_WAY | ARRIVED | IN_PROGRESS | COMPLETED | CANCELLED */
    @Column(nullable = false, length = 20)
    private String status;

    /** Self Drop only: {@code ServicePrice.benchFee} at booking time, so the fee
     *  the customer was shown is the one the technician's quote must use. */
    @Column(name = "bench_fee")
    private Double benchFee;

    /** IMMEDIATE | SCHEDULED | SELF_DROP. SELF_DROP = the customer brings the
     *  item to the technician's shop (no travel fee). */
    @Column(name = "booking_type", length = 20)
    private String bookingType;

    /** Snapshot of {@code ServicePrice.startingPrice} for this job's category at
     *  creation time - NOT the final repair cost. Never re-read live from
     *  ServicePrice so an admin's later price change can't rewrite history. */
    @Column(name = "starting_price")
    private Double startingPrice;

    /** {@code technician.technician_id} once dispatched. */
    @Column(name = "technician_id")
    private Long technicianId;

    /** {@code technician_service.id} when the customer booked one of the
     *  technician's own named/priced listings rather than a generic category
     *  request. Null for ordinary bookings. */
    @Column(name = "technician_service_id")
    private Long technicianServiceId;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "scheduled_at")
    private LocalDateTime scheduledAt;

    @Column(name = "assigned_at")
    private LocalDateTime assignedAt;

    @Column(name = "completed_at")
    private LocalDateTime completedAt;

    @Column(length = 2000)
    private String notes;

    public Job() {}
    public Long getId(){return id;} public void setId(Long v){id=v;}
    public String getCustomerName(){return customerName;} public void setCustomerName(String v){customerName=v;}
    public String getCustomerPhone(){return customerPhone;} public void setCustomerPhone(String v){customerPhone=v;}
    public Long getCustomerUserId(){return customerUserId;} public void setCustomerUserId(Long v){customerUserId=v;}
    public String getCategory(){return category;} public void setCategory(String v){category=v;}
    public String getDescription(){return description;} public void setDescription(String v){description=v;}
    public String getAddress(){return address;} public void setAddress(String v){address=v;}
    public Double getLat(){return lat;} public void setLat(Double v){lat=v;}
    public Double getLng(){return lng;} public void setLng(Double v){lng=v;}
    public String getStatus(){return status;} public void setStatus(String v){status=v;}
    public Long getTechnicianId(){return technicianId;} public void setTechnicianId(Long v){technicianId=v;}
    public LocalDateTime getCreatedAt(){return createdAt;} public void setCreatedAt(LocalDateTime v){createdAt=v;}
    public LocalDateTime getScheduledAt(){return scheduledAt;} public void setScheduledAt(LocalDateTime v){scheduledAt=v;}
    public LocalDateTime getAssignedAt(){return assignedAt;} public void setAssignedAt(LocalDateTime v){assignedAt=v;}
    public LocalDateTime getCompletedAt(){return completedAt;} public void setCompletedAt(LocalDateTime v){completedAt=v;}
    public String getNotes(){return notes;} public void setNotes(String v){notes=v;}
    public String getBookingType(){return bookingType;} public void setBookingType(String v){bookingType=v;}
    public Double getStartingPrice(){return startingPrice;} public void setStartingPrice(Double v){startingPrice=v;}
    public Double getBenchFee(){return benchFee;} public void setBenchFee(Double v){benchFee=v;}
    public Long getTechnicianServiceId(){return technicianServiceId;} public void setTechnicianServiceId(Long v){technicianServiceId=v;}

}
