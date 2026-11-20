package com.api.modules.notification.service;

import java.util.List;

import com.api.modules.notification.entity.Notification;
import com.api.modules.notification.dto.NotificationResponse;

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