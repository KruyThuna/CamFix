package com.api.controller;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.api.dto.chat.ChatMessageResponse;
import com.api.dto.chat.ChatThreadResponse;
import com.api.dto.chat.SendMessageRequest;
import com.api.service.ChatService;

/** Per-booking chat, shared by the customer app and the technician app. */
@RestController
public class ChatController {

    private static final String AUTH = "Authorization";

    private final ChatService chatService;

    public ChatController(ChatService chatService) {
        this.chatService = chatService;
    }

    /** The caller's conversations - one per booking they're a party to that
     *  has an assigned technician. Works for a customer or a technician
     *  account transparently. */
    @GetMapping("/api/chats/mine")
    public List<ChatThreadResponse> myThreads(
            @RequestHeader(value = AUTH, required = false) String auth) {
        return chatService.myThreads(auth);
    }

    @GetMapping("/api/bookings/{jobId}/messages")
    public List<ChatMessageResponse> list(
            @RequestHeader(value = AUTH, required = false) String auth,
            @PathVariable Long jobId) {
        return chatService.list(auth, jobId);
    }

    @PostMapping("/api/bookings/{jobId}/messages")
    public ResponseEntity<ChatMessageResponse> send(
            @RequestHeader(value = AUTH, required = false) String auth,
            @PathVariable Long jobId,
            @RequestBody SendMessageRequest body) {
        return ResponseEntity.status(HttpStatus.CREATED).body(chatService.send(auth, jobId, body));
    }
}
