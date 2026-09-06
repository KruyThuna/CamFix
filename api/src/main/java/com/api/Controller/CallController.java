package com.api.Controller;

import java.util.List;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.api.Service.CallService;
import com.api.dto.Request.StartCallRequest;
import com.api.dto.Response.CallHistoryResponse;

@RestController
@RequestMapping("/api/calls")
public class CallController {

    private final CallService callService;

    public CallController(CallService callService) {
        this.callService = callService;
    }

    @PostMapping("/start")
    public ResponseEntity<CallHistoryResponse> startCall(@RequestBody StartCallRequest request) {
        return ResponseEntity.ok(callService.startCall(request));
    }

    @PutMapping("/{callId}/end")
    public ResponseEntity<CallHistoryResponse> endCall(@PathVariable Long callId) {
        return ResponseEntity.ok(callService.endCall(callId));
    }

    @GetMapping("/user/{userId}")
    public ResponseEntity<List<CallHistoryResponse>> getByUser(@PathVariable Long userId) {
        return ResponseEntity.ok(callService.getCallHistoryByUser(userId));
    }

    @GetMapping("/technician/{technicianId}")
    public ResponseEntity<List<CallHistoryResponse>> getByTechnician(@PathVariable Long technicianId) {
        return ResponseEntity.ok(callService.getCallHistoryByTechnician(technicianId));
    }
}