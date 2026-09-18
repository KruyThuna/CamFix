package com.api.service;

import java.util.Comparator;
import java.util.List;
import java.util.NoSuchElementException;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.api.dto.chat.ChatMessageResponse;
import com.api.dto.chat.ChatThreadResponse;
import com.api.dto.chat.SendMessageRequest;
import com.api.entity.ChatMessage;
import com.api.entity.Job;
import com.api.entity.Technician;
import com.api.entity.Users;
import com.api.repository.ChatMessageRepository;
import com.api.repository.JobRepository;
import com.api.repository.TechnicianRepository;
import com.api.security.AuthSupport;

/**
 * Per-booking chat between a customer and their assigned technician. Polling,
 * not push - both apps re-fetch {@link #list} on a timer, the same pattern
 * {@code BookingsStore}/{@code NotificationsStore} already use client-side.
 *
 * <p>No Spring Security filter chain in this project (see {@code AdminService}
 * javadoc), so every entry point resolves the caller from the bearer token via
 * {@link AuthSupport} and re-checks they're actually a party to the job.
 */
@Service
@Transactional
public class ChatService {

    private static final String ROLE_TECHNICIAN = "TECHNICIAN";

    private final AuthSupport authSupport;
    private final JobRepository jobRepository;
    private final TechnicianRepository technicianRepository;
    private final ChatMessageRepository chatMessageRepository;
    private final NotificationDispatcher notifications;

    public ChatService(AuthSupport authSupport,
            JobRepository jobRepository,
            TechnicianRepository technicianRepository,
            ChatMessageRepository chatMessageRepository,
            NotificationDispatcher notifications) {
        this.authSupport = authSupport;
        this.jobRepository = jobRepository;
        this.technicianRepository = technicianRepository;
        this.chatMessageRepository = chatMessageRepository;
        this.notifications = notifications;
    }

    @Transactional(readOnly = true)
    public List<ChatMessageResponse> list(String authorization, Long jobId) {
        Users me = authSupport.currentUser(authorization);
        Job job = accessibleJob(me, jobId);
        String myName = displayName(me);
        String otherName = otherPartyName(job, me);
        return chatMessageRepository.findByJobIdOrderByCreatedAtAsc(jobId).stream()
                .map(m -> toDto(m, me, myName, otherName))
                .collect(Collectors.toList());
    }

    public ChatMessageResponse send(String authorization, Long jobId, SendMessageRequest req) {
        Users me = authSupport.currentUser(authorization);
        Job job = accessibleJob(me, jobId);
        String text = req == null ? null : req.getText();
        if (text == null || text.trim().isEmpty()) {
            throw new IllegalArgumentException("text is required");
        }

        ChatMessage m = new ChatMessage();
        m.setJobId(jobId);
        m.setSenderUserId(me.getUserId());
        m.setText(text.trim());
        m = chatMessageRepository.save(m);

        Long recipientUserId = otherPartyUserId(job, me);
        notifications.newChatMessage(recipientUserId, job, displayName(me), m.getText());

        return toDto(m, me, displayName(me), otherPartyName(job, me));
    }

    /** Every booking the caller is a party to that has a technician assigned
     *  (a thread needs two people, even before either has said anything). */
    @Transactional(readOnly = true)
    public List<ChatThreadResponse> myThreads(String authorization) {
        Users me = authSupport.currentUser(authorization);
        List<Job> jobs = ROLE_TECHNICIAN.equalsIgnoreCase(nz(me.getRole()))
                ? myTechnicianJobs(me)
                : jobRepository.findByCustomerUserId(me.getUserId());

        return jobs.stream()
                .filter(j -> j.getTechnicianId() != null)
                .sorted(Comparator.comparing(Job::getId).reversed())
                .map(j -> toThreadDto(j, me))
                .collect(Collectors.toList());
    }

    private List<Job> myTechnicianJobs(Users me) {
        return technicianRepository.findByUsers_UserId(me.getUserId())
                .map(t -> jobRepository.findByTechnicianId(t.getTechnicianId()))
                .orElse(List.of());
    }

    private ChatThreadResponse toThreadDto(Job job, Users me) {
        ChatThreadResponse r = new ChatThreadResponse();
        r.setJobId(job.getId());
        r.setCategory(job.getCategory());
        r.setStatus(job.getStatus());
        r.setOtherPartyName(otherPartyName(job, me));

        List<ChatMessage> messages = chatMessageRepository.findByJobIdOrderByCreatedAtAsc(job.getId());
        if (!messages.isEmpty()) {
            ChatMessage last = messages.get(messages.size() - 1);
            r.setLastMessage(last.getText());
            r.setLastMessageAt(last.getCreatedAt() == null ? null : last.getCreatedAt().toString());
            r.setLastMessageMine(last.getSenderUserId().equals(me.getUserId()));
        }
        return r;
    }

    // --- Access control -------------------------------------------------------

    private Job accessibleJob(Users me, Long jobId) {
        Job job = jobRepository.findById(jobId)
                .orElseThrow(() -> new NoSuchElementException("Booking not found: " + jobId));
        boolean isCustomer = me.getUserId().equals(job.getCustomerUserId());
        boolean isTechnician = job.getTechnicianId() != null && isAssignedTechnician(me, job.getTechnicianId());
        if (!isCustomer && !isTechnician) {
            // Don't distinguish "not yours" from "doesn't exist".
            throw new NoSuchElementException("Booking not found: " + jobId);
        }
        return job;
    }

    private boolean isAssignedTechnician(Users me, Long technicianId) {
        return technicianRepository.findById(technicianId)
                .map(Technician::getUsers)
                .map(Users::getUserId)
                .map(me.getUserId()::equals)
                .orElse(false);
    }

    private Long otherPartyUserId(Job job, Users me) {
        boolean iAmCustomer = me.getUserId().equals(job.getCustomerUserId());
        if (iAmCustomer) {
            if (job.getTechnicianId() == null) {
                return null;
            }
            return technicianRepository.findById(job.getTechnicianId())
                    .map(Technician::getUsers)
                    .map(Users::getUserId)
                    .orElse(null);
        }
        return job.getCustomerUserId();
    }

    private String otherPartyName(Job job, Users me) {
        boolean iAmCustomer = me.getUserId().equals(job.getCustomerUserId());
        if (iAmCustomer) {
            if (job.getTechnicianId() == null) {
                return "Technician";
            }
            return technicianRepository.findById(job.getTechnicianId())
                    .map(t -> {
                        Users u = t.getUsers();
                        if (u == null) {
                            return t.getBusinessName();
                        }
                        String n = (nz(u.getFirstName()) + " " + nz(u.getLastName())).trim();
                        return n.isEmpty() ? t.getBusinessName() : n;
                    })
                    .orElse("Technician");
        }
        return nz(job.getCustomerName());
    }

    private static String displayName(Users u) {
        String n = (nz(u.getFirstName()) + " " + nz(u.getLastName())).trim();
        return n.isEmpty() || "-".equals(n) ? nz(u.getEmail()) : n;
    }

    private static String nz(String v) {
        return v == null ? "" : v;
    }

    private ChatMessageResponse toDto(ChatMessage m, Users me, String myName, String otherName) {
        boolean mine = m.getSenderUserId().equals(me.getUserId());
        ChatMessageResponse r = new ChatMessageResponse();
        r.setId(m.getId());
        r.setJobId(m.getJobId());
        r.setSenderUserId(m.getSenderUserId());
        r.setMine(mine);
        r.setSenderName(mine ? myName : otherName);
        r.setText(m.getText());
        r.setCreatedAt(m.getCreatedAt() == null ? null : m.getCreatedAt().toString());
        return r;
    }
}
