package com.api.dto.admin;

import lombok.Getter;
import lombok.Setter;

/** Payload for {@code GET /api/admin/stats}. */
@Getter
@Setter
public class DashboardStatsResponse {

    private long pendingTechnicians;
    private long activeTechnicians;
    private long suspendedTechnicians;
    private long openJobs;
    private long unassignedJobs;
    private long completedJobs;
}
