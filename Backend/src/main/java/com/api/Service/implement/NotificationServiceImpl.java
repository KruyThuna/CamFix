package com.api.Service.implement;

import java.util.List;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;
import com.api.Entity.Notification;
import com.api.Entity.Users;
import com.api.Repo.NotificationRepository;
import com.api.Repo.UserRepository;
import com.api.Service.NotificationService;
import com.api.dto.Response.NotificationResponse;

@Service
public class NotificationServiceImpl implements NotificationService {

    private final NotificationRepository notificationRepository;
    private final UserRepository userRepository;

    public NotificationServiceImpl(NotificationRepository notificationRepository,
            UserRepository userRepository) {
        this.notificationRepository = notificationRepository;
        this.userRepository = userRepository;
    }

    @Override
    public NotificationResponse createNotification(Notification request) {

        Users user = userRepository.findById(request.getUser().getUserId())
                .orElseThrow(() -> new RuntimeException("User not found"));

        request.setUser(user);

        Notification notification = notificationRepository.save(request);

        return mapToResponse(notification);
    }

    @Override
    public NotificationResponse getById(Long id) {

        Notification notification = notificationRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Notification not found"));

        return mapToResponse(notification);
    }

    @Override
    public List<NotificationResponse> getAll() {

        return notificationRepository.findAll()
                .stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    @Override
    public List<NotificationResponse> getByUser(Long userId) {

        return notificationRepository.findByUserUserId(userId)
                .stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    @Override
    public NotificationResponse update(Long id, Notification request) {

        Notification notification = notificationRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Notification not found"));

        notification.setTitle(request.getTitle());
        notification.setMessage(request.getMessage());
        notification.setRead(request.isRead());

        Notification updated = notificationRepository.save(notification);

        return mapToResponse(updated);
    }

    @Override
    public void delete(Long id) {

        Notification notification = notificationRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Notification not found"));

        notificationRepository.delete(notification);
    }

    @Override
    public Notification findByNotificationId(Long notificationId) {

        return notificationRepository.findById(notificationId)
                .orElseThrow(() -> new RuntimeException("Notification not found"));
    }

    private NotificationResponse mapToResponse(Notification notification) {

        NotificationResponse response = new NotificationResponse();

        response.setNotificationId(notification.getNotificationId());
        response.setTitle(notification.getTitle());
        response.setMessage(notification.getMessage());
        response.setRead(notification.isRead());
        response.setCreatedAt(notification.getCreatedAt());

        if (notification.getUser() != null) {
            response.setUserId(notification.getUser().getUserId());
        }

        return response;
    }

    @Override
    public List<Notification> findByUsersUserId(Long userId) {
        return notificationRepository.findByUserUserId(userId);
    }

}