package com.api.Service;

import java.util.List;

import com.api.dto.Request.StartCallRequest;
import com.api.dto.Response.CallHistoryResponse;

/** Bearer-token identifies the caller for every method - no raw user/technician
 *  ids taken from the client, so one customer can't read or end another's calls. */
public interface CallService {
    CallHistoryResponse startCall(String authorization, StartCallRequest request);

    CallHistoryResponse endCall(String authorization, Long callId);

    List<CallHistoryResponse> mine(String authorization);

    List<CallHistoryResponse> forTechnician(Long technicianId);
}
