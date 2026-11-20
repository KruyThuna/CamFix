package com.api.modules.chat.service;


import com.api.modules.technician.entity.Technician;
import java.util.List;

import com.api.modules.chat.dto.StartCallRequest;
import com.api.modules.chat.dto.CallHistoryResponse;

/** Bearer-token identifies the caller for every method - no raw user/technician
 *  ids taken from the client, so one customer can't read or end another's calls. */
public interface CallService {
    CallHistoryResponse startCall(String authorization, StartCallRequest request);

    CallHistoryResponse endCall(String authorization, Long callId);

    List<CallHistoryResponse> mine(String authorization);

    List<CallHistoryResponse> forTechnician(Long technicianId);
}
