package com.api.controller;

import java.util.List;
import java.util.Map;

import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.api.entity.Notification;
import com.api.entity.Users;
import com.api.repository.NotificationRepository;
import com.api.security.AuthSupport;
import com.api.dto.notification.NotificationItem;

/**
 * The signed-in user's own notification feed. Separate from the CRUD
 * {@code NotificationController} (which is admin/testing plumbing) - these
 * endpoints are scoped to the caller's bearer token.
 */
@RestController
@RequestMapping("/api/notifications/mine")
@Transactional
public class NotificationSelfController {

    private static final String AUTH = "Authorization";

    private final AuthSupport authSupport;
    private final NotificationRepository notificationRepository;

    public NotificationSelfController(AuthSupport authSupport,
            NotificationRepository notificationRepository) {
        this.authSupport = authSupport;
        this.notificationRepository = notificationRepository;
    }

    @GetMapping
    @Transactional(readOnly = true)
    public List<NotificationItem> list(@RequestHeader(value = AUTH, required = false) String auth) {
        Users me = authSupport.currentUser(auth);
        return notificationRepository.findByUser_UserIdOrderByCreatedAtDesc(me.getUserId())
                .stream().map(NotificationItem::of).toList();
    }

    @GetMapping("/unread-count")
    @Transactional(readOnly = true)
    public Map<String, Long> unreadCount(@RequestHeader(value = AUTH, required = false) String auth) {
        Users me = authSupport.currentUser(auth);
        return Map.of("count", notificationRepository.countByUser_UserIdAndIsReadFalse(me.getUserId()));
    }

    @PostMapping("/read-all")
    public Map<String, Object> readAll(@RequestHeader(value = AUTH, required = false) String auth) {
        Users me = authSupport.currentUser(auth);
        List<Notification> unread = notificationRepository.findByUser_UserIdAndIsReadFalse(me.getUserId());
        unread.forEach(n -> n.setRead(true));
        notificationRepository.saveAll(unread);
        return Map.of("updated", unread.size());
    }

    @PostMapping("/{id}/read")
    public NotificationItem readOne(
            @RequestHeader(value = AUTH, required = false) String auth,
            @PathVariable Long id) {
        Users me = authSupport.currentUser(auth);
        Notification n = notificationRepository.findById(id)
                .filter(x -> x.getUser() != null && me.getUserId().equals(x.getUser().getUserId()))
                .orElseThrow(() -> new java.util.NoSuchElementException("Notification not found: " + id));
        n.setRead(true);
        return NotificationItem.of(notificationRepository.save(n));
    }
}
