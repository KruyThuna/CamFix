package com.api.Service;

import java.util.List;

import com.api.Entity.Notification;
import com.api.dto.Response.NotificationResponse;

public interface NotificationService {

    NotificationResponse createNotification(Notification request);

    NotificationResponse getById(Long id);

    List<NotificationResponse> getAll();

    List<NotificationResponse> getByUser(Long userId);

    NotificationResponse update(Long id, Notification request);

    void delete(Long id);

    List<Notification> findByUsersUserId(Long userId);

    Notification findByNotificationId(Long notificationId);

}