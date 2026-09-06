package com.api.Controller;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.api.Entity.Notification;
import com.api.Service.NotificationService;
import com.api.dto.Response.NotificationResponse;

@RestController
@RequestMapping("/api/notifications")
@CrossOrigin("*")
public class NotificationController {

        private final NotificationService notificationService;

        public NotificationController(NotificationService notificationService) {
                this.notificationService = notificationService;
        }

        // Create Notification
        @PostMapping
        public ResponseEntity<NotificationResponse> createNotification(
                        @RequestBody Notification request) {

                NotificationResponse response = notificationService.createNotification(request);

                return new ResponseEntity<>(response, HttpStatus.CREATED);
        }

        // Get Notification By ID
        @GetMapping("/{id}")
        public ResponseEntity<NotificationResponse> getById(
                        @PathVariable Long id) {

                return ResponseEntity.ok(
                                notificationService.getById(id));
        }

        // Get All Notifications
        @GetMapping
        public ResponseEntity<List<NotificationResponse>> getAll() {

                return ResponseEntity.ok(
                                notificationService.getAll());
        }

        // Get Notifications By User ID
        @GetMapping("/user/{userId}")
        public ResponseEntity<List<NotificationResponse>> getByUser(
                        @PathVariable Long userId) {

                return ResponseEntity.ok(
                                notificationService.getByUser(userId));
        }

        // Update Notification
        @PutMapping("/{id}")
        public ResponseEntity<NotificationResponse> update(
                        @PathVariable Long id,
                        @RequestBody Notification request) {

                return ResponseEntity.ok(
                                notificationService.update(id, request));
        }

        // Delete Notification
        @DeleteMapping("/{id}")
        public ResponseEntity<String> delete(
                        @PathVariable Long id) {

                notificationService.delete(id);

                return ResponseEntity.ok(
                                "Notification deleted successfully");
        }

        // Find Notification Entity By ID
        @GetMapping("/entity/{notificationId}")
        public ResponseEntity<Notification> findByNotificationId(
                        @PathVariable Long notificationId) {

                return ResponseEntity.ok(
                                notificationService.findByNotificationId(notificationId));
        }

        // Find Notifications By User ID (Entity List)
        @GetMapping("/entity/user/{userId}")
        public ResponseEntity<List<Notification>> findByUsersUserId(
                        @PathVariable Long userId) {

                return ResponseEntity.ok(
                                notificationService.findByUsersUserId(userId));
        }
}