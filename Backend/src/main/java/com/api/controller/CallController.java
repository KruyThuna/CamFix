package com.api.controller;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.api.service.CallService;
import com.api.dto.request.StartCallRequest;
import com.api.dto.response.CallHistoryResponse;

/** Call logging for the signed-in customer (`/api/calls/**`). */
@RestController
@RequestMapping("/api/calls")
public class CallController {

    private static final String AUTH = "Authorization";

    private final CallService callService;

    public CallController(CallService callService) {
        this.callService = callService;
    }

    @PostMapping("/start")
    public ResponseEntity<CallHistoryResponse> startCall(
            @RequestHeader(value = AUTH, required = false) String auth,
            @RequestBody StartCallRequest request) {
        return ResponseEntity.ok(callService.startCall(auth, request));
    }

    @PutMapping("/{callId}/end")
    public ResponseEntity<CallHistoryResponse> endCall(
            @RequestHeader(value = AUTH, required = false) String auth,
            @PathVariable Long callId) {
        return ResponseEntity.ok(callService.endCall(auth, callId));
    }

    @GetMapping("/mine")
    public ResponseEntity<List<CallHistoryResponse>> mine(
            @RequestHeader(value = AUTH, required = false) String auth) {
        return ResponseEntity.ok(callService.mine(auth));
    }
}
