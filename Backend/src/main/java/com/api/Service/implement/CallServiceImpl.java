package com.api.Service.implement;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.List;
import java.util.NoSuchElementException;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.api.Entity.CallHistory;
import com.api.Entity.Technician;
import com.api.Entity.Users;
import com.api.Repo.CallHistoryRepository;
import com.api.Repo.TechnicianRepository;
import com.api.Security.AuthSupport;
import com.api.Service.CallService;
import com.api.dto.Request.StartCallRequest;
import com.api.dto.Response.CallHistoryResponse;

@Service
@Transactional
public class CallServiceImpl implements CallService {

    private static final String STATUS_ONGOING = "ONGOING";
    private static final String STATUS_COMPLETED = "COMPLETED";

    private final AuthSupport authSupport;
    private final CallHistoryRepository callHistoryRepository;
    private final TechnicianRepository technicianRepository;

    public CallServiceImpl(
            AuthSupport authSupport,
            CallHistoryRepository callHistoryRepository,
            TechnicianRepository technicianRepository) {
        this.authSupport = authSupport;
        this.callHistoryRepository = callHistoryRepository;
        this.technicianRepository = technicianRepository;
    }

    @Override
    public CallHistoryResponse startCall(String authorization, StartCallRequest request) {
        Users me = authSupport.currentUser(authorization);
        Long technicianId = request == null ? null : request.getTechnicianId();
        if (technicianId == null) {
            throw new IllegalArgumentException("technicianId is required");
        }
        Technician technician = technicianRepository.findById(technicianId)
                .orElseThrow(() -> new NoSuchElementException("Technician not found: " + technicianId));

        CallHistory call = new CallHistory();
        call.setUser(me);
        call.setTechnician(technician);
        call.setCallStatus(STATUS_ONGOING);
        call.setStartedAt(LocalDateTime.now());

        return toDto(callHistoryRepository.save(call));
    }

    @Override
    public CallHistoryResponse endCall(String authorization, Long callId) {
        Users me = authSupport.currentUser(authorization);
        CallHistory call = callHistoryRepository.findByCallIdAndUser_UserId(callId, me.getUserId())
                .orElseThrow(() -> new NoSuchElementException("Call not found: " + callId));

        LocalDateTime now = LocalDateTime.now();
        call.setEndedAt(now);
        call.setCallStatus(STATUS_COMPLETED);
        if (call.getStartedAt() != null) {
            call.setDurationSeconds((int) Duration.between(call.getStartedAt(), now).getSeconds());
        }
        return toDto(callHistoryRepository.save(call));
    }

    @Override
    @Transactional(readOnly = true)
    public List<CallHistoryResponse> mine(String authorization) {
        Users me = authSupport.currentUser(authorization);
        return callHistoryRepository.findByUser_UserIdOrderByCreatedAtDesc(me.getUserId())
                .stream().map(CallServiceImpl::toDto).collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public List<CallHistoryResponse> forTechnician(Long technicianId) {
        return callHistoryRepository.findByTechnician_TechnicianIdOrderByCreatedAtDesc(technicianId)
                .stream().map(CallServiceImpl::toDto).collect(Collectors.toList());
    }

    private static CallHistoryResponse toDto(CallHistory entity) {
        Users u = entity.getUser();
        Technician t = entity.getTechnician();
        return CallHistoryResponse.builder()
                .callId(entity.getCallId())
                .userId(u != null ? u.getUserId() : null)
                .userName(u != null ? nz(u.getFirstName()) + " " + nz(u.getLastName()) : null)
                .technicianId(t != null ? t.getTechnicianId() : null)
                .technicianName(t != null ? technicianName(t) : null)
                .callStatus(entity.getCallStatus())
                .startedAt(entity.getStartedAt())
                .endedAt(entity.getEndedAt())
                .durationSeconds(entity.getDurationSeconds())
                .createdAt(entity.getCreatedAt())
                .build();
    }

    private static String technicianName(Technician t) {
        Users u = t.getUsers();
        if (u == null) {
            return t.getBusinessName();
        }
        String n = (nz(u.getFirstName()) + " " + nz(u.getLastName())).trim();
        return n.isEmpty() ? t.getBusinessName() : n;
    }

    private static String nz(String v) {
        return v == null ? "" : v;
    }
}
