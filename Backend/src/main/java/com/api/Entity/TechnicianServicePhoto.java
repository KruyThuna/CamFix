package com.api.Entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/**
 * The photo a technician attached to one of their own service listings.
 * Kept in its own table (keyed by the listing id) so listing queries never
 * drag image bytes along - see {@link TechnicianServiceListing#getPhotoContentType()}
 * for whether one exists.
 */
@Entity
@Table(name = "technician_service_photo")
public class TechnicianServicePhoto {

    @Id
    @Column(name = "listing_id")
    private Long listingId;

    @Column(name = "data", nullable = false, columnDefinition = "LONGBLOB")
    private byte[] data;

    @Column(name = "content_type", nullable = false, length = 100)
    private String contentType;

    public Long getListingId() {
        return listingId;
    }

    public void setListingId(Long listingId) {
        this.listingId = listingId;
    }

    public byte[] getData() {
        return data;
    }

    public void setData(byte[] data) {
        this.data = data;
    }

    public String getContentType() {
        return contentType;
    }

    public void setContentType(String contentType) {
        this.contentType = contentType;
    }
}
