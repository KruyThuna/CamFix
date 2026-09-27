package com.api.dto.Technician;

import lombok.Getter;
import lombok.Setter;

/** One of a technician's named/priced service listings, with a real
 *  completed-job count computed live from {@code Job} - never a stored,
 *  driftable counter. */
@Getter
@Setter
public class TechnicianServiceResponse {

    private Long id;
    private Long technicianId;
    private String title;
    private Double price;
    private String description;
    private long completedJobCount;
    /** Relative URL of the listing's own photo, or null when none uploaded. */
    private String photoUrl;
}
