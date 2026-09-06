package com.api.Service.implement;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.api.Entity.CallHistory;
import com.api.Entity.Technician;
import com.api.Entity.Users;
import com.api.Repo.CallHistoryRepository;
import com.api.Repo.TechnicianRepository;
import com.api.Repo.UserRepository;
import com.api.Service.CallService;
import com.api.dto.Request.StartCallRequest;
import com.api.dto.Response.CallHistoryResponse;

@Service
public class CallServiceImpl implements CallService {

    private final CallHistoryRepository callHistoryRepository;
    private final UserRepository userRepository;
    private final TechnicianRepository technicianRepository;

    public CallServiceImpl(
            CallHistoryRepository callHistoryRepository,
            UserRepository userRepository,
            TechnicianRepository technicianRepository) {
        this.callHistoryRepository = callHistoryRepository;
        this.userRepository = userRepository;
        this.technicianRepository = technicianRepository;
    }

    @Override
    @Transactional
    public CallHistoryResponse startCall(StartCallRequest request) {
        Users user = userRepository.findById(request.getUserId())
                .orElseThrow(() -> new RuntimeException("User not found with id: " + request.getUserId()));

        Technician technician = technicianRepository.findById(request.getTechnicianId())
                .orElseThrow(() -> new RuntimeException("Technician not found with id: " + request.getTechnicianId()));

        CallHistory call = new CallHistory();
        call.setUser(user);
        call.setTechnician(technician);
        call.setCallStatus("ONGOING");
        call.setStartedAt(LocalDateTime.now());

        CallHistory saved = callHistoryRepository.save(call);
        return mapToResponse(saved);
    }

    @Override
    @Transactional
    public CallHistoryResponse endCall(Long callId) {
        CallHistory call = callHistoryRepository.findById(callId)
                .orElseThrow(() -> new RuntimeException("Call not found with id: " + callId));

        LocalDateTime now = LocalDateTime.now();
        call.setEndedAt(now);
        call.setCallStatus("COMPLETED");

        if (call.getStartedAt() != null) {
            long seconds = Duration.between(call.getStartedAt(), now).getSeconds();
            call.setDurationSeconds((int) seconds);
        }

        CallHistory updated = callHistoryRepository.save(call);
        return mapToResponse(updated);
    }

    @Override
    @Transactional(readOnly = true)
    public List<CallHistoryResponse> getCallHistoryByUser(Long userId) {
        return callHistoryRepository.findByUser_UserId(userId)
                .stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public List<CallHistoryResponse> getCallHistoryByTechnician(Long technicianId) {
        return callHistoryRepository.findByTechnician_TechnicianId(technicianId)
                .stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    private CallHistoryResponse mapToResponse(CallHistory entity) {
        return CallHistoryResponse.builder()
                .callId(entity.getCallId())
                .userId(entity.getUser() != null ? entity.getUser().getUserId() : null)
                .userName(entity.getUser() != null ? entity.getUser().getFirstName() : null)
                .technicianId(entity.getTechnician() != null ? entity.getTechnician().getTechnicianId() : null)
                .callStatus(entity.getCallStatus())
                .startedAt(entity.getStartedAt())
                .endedAt(entity.getEndedAt())
                .durationSeconds(entity.getDurationSeconds())
                .createdAt(entity.getCreatedAt())
                .build();
    }
}