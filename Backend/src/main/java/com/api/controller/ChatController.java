package com.api.controller;

import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.api.service.ChatService;
import com.api.dto.chat.ChatDtos.MessageResponse;
import com.api.dto.chat.ChatDtos.SendMessageRequest;
import com.api.dto.chat.ChatDtos.ThreadResponse;

/** Per-booking chat, shared by the customer and technician apps. */
@RestController
@RequestMapping("/api/chats")
public class ChatController {

    private static final String AUTH = "Authorization";

    private final ChatService chatService;

    public ChatController(ChatService chatService) {
        this.chatService = chatService;
    }

    @GetMapping
    public List<ThreadResponse> threads(@RequestHeader(value = AUTH, required = false) String auth) {
        return chatService.threads(auth);
    }

    @GetMapping("/{jobId}/messages")
    public List<MessageResponse> messages(
            @RequestHeader(value = AUTH, required = false) String auth,
            @PathVariable Long jobId,
            @RequestParam(required = false) Long after) {
        return chatService.messages(auth, jobId, after);
    }

    @PostMapping("/{jobId}/messages")
    public MessageResponse send(
            @RequestHeader(value = AUTH, required = false) String auth,
            @PathVariable Long jobId,
            @RequestBody(required = false) SendMessageRequest body) {
        return chatService.send(auth, jobId, body == null ? null : body.body());
    }
}
