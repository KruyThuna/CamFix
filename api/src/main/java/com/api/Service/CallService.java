package com.api.Service;

import java.util.List;
import com.api.dto.Request.StartCallRequest;
import com.api.dto.Response.CallHistoryResponse;

public interface CallService {
    CallHistoryResponse startCall(StartCallRequest request);

    CallHistoryResponse endCall(Long callId);

    List<CallHistoryResponse> getCallHistoryByUser(Long userId);

    List<CallHistoryResponse> getCallHistoryByTechnician(Long technicianId);
}