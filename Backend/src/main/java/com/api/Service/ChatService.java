package com.api.Service;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.NoSuchElementException;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.api.Entity.ChatMessage;
import com.api.Entity.Job;
import com.api.Entity.Technician;
import com.api.Entity.Users;
import com.api.Repo.ChatMessageRepository;
import com.api.Repo.JobRepository;
import com.api.Repo.TechnicianRepository;
import com.api.Repo.UserRepository;
import com.api.Security.AuthSupport;
import com.api.dto.Chat.ChatDtos.MessageResponse;
import com.api.dto.Chat.ChatDtos.ThreadResponse;

/**
 * Real per-booking chat between a customer and the technician assigned to
 * that booking. The caller's side (CUSTOMER / TECHNICIAN) is derived from
 * the job itself - anyone who is neither gets "not found".
 */
@Service
public class ChatService {

    static final String ROLE_CUSTOMER = "CUSTOMER";
    static final String ROLE_TECHNICIAN = "TECHNICIAN";
    private static final int MAX_BODY = 2000;
    public static final String CHAT_MESSAGE = "CHAT_MESSAGE";

    private final AuthSupport authSupport;
    private final JobRepository jobRepository;
    private final TechnicianRepository technicianRepository;
    private final UserRepository userRepository;
    private final ChatMessageRepository chatRepository;
    private final NotificationDispatcher notifications;

    public ChatService(AuthSupport authSupport, JobRepository jobRepository,
            TechnicianRepository technicianRepository, UserRepository userRepository,
            ChatMessageRepository chatRepository, NotificationDispatcher notifications) {
        this.authSupport = authSupport;
        this.jobRepository = jobRepository;
        this.technicianRepository = technicianRepository;
        this.userRepository = userRepository;
        this.chatRepository = chatRepository;
        this.notifications = notifications;
    }

    /** Who the caller is on a job. */
    private record Seat(Users me, Job job, String role) {
    }

    private Seat seat(String authorization, Long jobId) {
        Users me = authSupport.currentUser(authorization);
        Job job = jobRepository.findById(jobId)
                .orElseThrow(() -> new NoSuchElementException("Chat not found: " + jobId));
        if (job.getTechnicianId() == null) {
            // No technician yet - nobody to talk to.
            throw new NoSuchElementException("Chat not found: " + jobId);
        }
        if (me.getUserId().equals(job.getCustomerUserId())) {
            return new Seat(me, job, ROLE_CUSTOMER);
        }
        Technician tech = technicianRepository.findByUsers_UserId(me.getUserId()).orElse(null);
        if (tech != null && tech.getTechnicianId().equals(job.getTechnicianId())) {
            return new Seat(me, job, ROLE_TECHNICIAN);
        }
        throw new NoSuchElementException("Chat not found: " + jobId);
    }

    private static String other(String role) {
        return ROLE_CUSTOMER.equals(role) ? ROLE_TECHNICIAN : ROLE_CUSTOMER;
    }

    /** Messages in a thread (optionally only those after {@code afterId});
     *  marks the other side's messages as read. */
    @Transactional
    public List<MessageResponse> messages(String authorization, Long jobId, Long afterId) {
        Seat s = seat(authorization, jobId);
        List<ChatMessage> unread =
                chatRepository.findByJobIdAndSenderRoleAndReadAtIsNull(jobId, other(s.role()));
        if (!unread.isEmpty()) {
            LocalDateTime now = LocalDateTime.now();
            unread.forEach(m -> m.setReadAt(now));
            chatRepository.saveAll(unread);
        }
        List<ChatMessage> list = afterId == null
                ? chatRepository.findByJobIdOrderByIdAsc(jobId)
                : chatRepository.findByJobIdAndIdGreaterThanOrderByIdAsc(jobId, afterId);
        return list.stream().map(m -> toDto(m, s.role())).collect(Collectors.toList());
    }

    @Transactional
    public MessageResponse send(String authorization, Long jobId, String body) {
        Seat s = seat(authorization, jobId);
        String text = body == null ? "" : body.trim();
        if (text.isEmpty()) {
            throw new IllegalArgumentException("Message can't be empty");
        }
        if (text.length() > MAX_BODY) {
            throw new IllegalArgumentException("Message is too long (max " + MAX_BODY + " characters)");
        }
        String otherRole = other(s.role());
        // Notify only on the first unread message, so a burst of messages
        // doesn't flood the other person's notification list.
        boolean firstUnread = chatRepository
                .findByJobIdAndSenderRoleAndReadAtIsNull(jobId, s.role()).isEmpty();

        ChatMessage m = new ChatMessage();
        m.setJobId(jobId);
        m.setSenderUserId(s.me().getUserId());
        m.setSenderRole(s.role());
        m.setBody(text);
        m = chatRepository.save(m);

        if (firstUnread) {
            Long recipient = ROLE_TECHNICIAN.equals(otherRole)
                    ? technicianUserId(s.job().getTechnicianId())
                    : s.job().getCustomerUserId();
            String who = displayName(s.me());
            String preview = text.length() > 80 ? text.substring(0, 80) + "…" : text;
            notifications.push(recipient, CHAT_MESSAGE, jobId,
                    "New message from " + who, preview,
                    "សារថ្មីពី " + who, preview);
        }
        return toDto(m, s.role());
    }

    /** Every conversation the caller is part of, most recent activity first.
     *  Transactional so the technician's lazily-loaded {@code Users} can be read. */
    @Transactional(readOnly = true)
    public List<ThreadResponse> threads(String authorization) {
        Users me = authSupport.currentUser(authorization);
        Technician myTech = technicianRepository.findByUsers_UserId(me.getUserId()).orElse(null);
        List<Job> jobs = jobRepository.findAll().stream()
                .filter(j -> j.getTechnicianId() != null)
                .filter(j -> me.getUserId().equals(j.getCustomerUserId())
                        || (myTech != null && myTech.getTechnicianId().equals(j.getTechnicianId())))
                .collect(Collectors.toList());
        if (jobs.isEmpty()) {
            return List.of();
        }
        Map<Long, List<ChatMessage>> byJob = chatRepository
                .findByJobIdIn(jobs.stream().map(Job::getId).collect(Collectors.toList()))
                .stream().collect(Collectors.groupingBy(ChatMessage::getJobId));

        List<ThreadResponse> out = new ArrayList<>();
        for (Job j : jobs) {
            String role = me.getUserId().equals(j.getCustomerUserId()) ? ROLE_CUSTOMER : ROLE_TECHNICIAN;
            List<ChatMessage> msgs = byJob.getOrDefault(j.getId(), List.of());
            ChatMessage last = msgs.stream().max(Comparator.comparing(ChatMessage::getId)).orElse(null);
            int unread = (int) msgs.stream()
                    .filter(m -> !role.equals(m.getSenderRole()) && m.getReadAt() == null)
                    .count();
            String otherName;
            String otherPhone;
            Long otherTechId = null;
            if (ROLE_CUSTOMER.equals(role)) {
                Technician t = technicianRepository.findById(j.getTechnicianId()).orElse(null);
                Users tu = t == null ? null : t.getUsers();
                otherName = tu == null ? "Technician" : displayName(tu);
                otherPhone = tu == null ? null : tu.getPhoneNumber();
                otherTechId = j.getTechnicianId();
            } else {
                Users cu = j.getCustomerUserId() == null ? null
                        : userRepository.findById(j.getCustomerUserId()).orElse(null);
                otherName = cu == null ? "Customer" : displayName(cu);
                otherPhone = cu == null ? null : cu.getPhoneNumber();
            }
            out.add(new ThreadResponse(j.getId(), j.getCategory(), j.getStatus(), role,
                    otherName, otherPhone, otherTechId,
                    last == null ? null : last.getBody(),
                    last != null && role.equals(last.getSenderRole()),
                    last == null ? null : last.getCreatedAt(),
                    unread));
        }
        // Threads with messages first (newest activity), then the rest by job id.
        out.sort(Comparator
                .comparing((ThreadResponse t) -> t.lastAt() == null)
                .thenComparing(ThreadResponse::lastAt, Comparator.nullsLast(Comparator.reverseOrder()))
                .thenComparing(ThreadResponse::jobId, Comparator.reverseOrder()));
        return out;
    }

    private Long technicianUserId(Long technicianId) {
        return technicianRepository.findById(technicianId)
                .map(Technician::getUsers)
                .map(Users::getUserId)
                .orElse(null);
    }

    private static String displayName(Users u) {
        String n = ((u.getFirstName() == null ? "" : u.getFirstName()) + " "
                + (u.getLastName() == null ? "" : u.getLastName())).trim();
        if (n.isEmpty() || "-".equals(n)) {
            return u.getEmail() == null ? "User" : u.getEmail();
        }
        return n;
    }

    private static MessageResponse toDto(ChatMessage m, String myRole) {
        return new MessageResponse(m.getId(), m.getJobId(), m.getSenderRole(),
                myRole.equals(m.getSenderRole()), m.getBody(), m.getCreatedAt(), m.getReadAt());
    }
}
