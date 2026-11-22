package com.api.modules.telegram.service;

import com.api.common.security.JwtService;
import com.api.modules.payment.entity.Payment;
import com.api.modules.payment.entity.TechnicianWalletEntry;
import com.api.modules.payment.repository.TechnicianWalletEntryRepository;
import com.api.modules.telegram.entity.TelegramLinkCode;
import com.api.modules.telegram.entity.TelegramTechnicianLink;
import com.api.modules.telegram.repository.TelegramLinkCodeRepository;
import com.api.modules.telegram.repository.TelegramTechnicianLinkRepository;
import com.api.modules.technician.entity.Technician;
import com.api.modules.technician.repository.TechnicianRepository;
import com.api.modules.user.entity.Users;
import com.api.modules.user.repository.UserRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.HexFormat;
import java.util.NoSuchElementException;
import org.springframework.beans.factory.annotation.Value;
import jakarta.annotation.PostConstruct;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import static org.springframework.http.HttpStatus.UNAUTHORIZED;

@Service
public class TelegramWalletService {
    private final JwtService jwt;
    private final UserRepository users;
    private final TechnicianRepository technicians;
    private final TelegramLinkCodeRepository codes;
    private final TelegramTechnicianLinkRepository links;
    private final TechnicianWalletEntryRepository wallet;
    private final String botToken;
    private final String botUsername;
    private final String webhookSecret;
    private final String webhookUrl;
    private final ObjectMapper mapper = new ObjectMapper();
    private final HttpClient http = HttpClient.newHttpClient();
    private final SecureRandom random = new SecureRandom();

    public TelegramWalletService(JwtService jwt, UserRepository users, TechnicianRepository technicians,
            TelegramLinkCodeRepository codes, TelegramTechnicianLinkRepository links,
            TechnicianWalletEntryRepository wallet,
            @Value("${app.telegram.bot-token:}") String botToken,
            @Value("${app.telegram.bot-username:Camfix_bot}") String botUsername,
            @Value("${app.telegram.webhook-secret:}") String webhookSecret,
            @Value("${app.telegram.webhook-url:}") String webhookUrl) {
        this.jwt = jwt; this.users = users; this.technicians = technicians;
        this.codes = codes; this.links = links; this.wallet = wallet;
        this.botToken = botToken == null ? "" : botToken.trim();
        this.botUsername = botUsername == null ? "Camfix_bot" : botUsername.replace("@", "").trim();
        this.webhookSecret = webhookSecret == null ? "" : webhookSecret;
        this.webhookUrl = webhookUrl == null ? "" : webhookUrl.trim();
    }

    @PostConstruct
    void configureWebhook() {
        if (botToken.isBlank() || webhookUrl.isBlank() || webhookSecret.isBlank()) return;
        try {
            String body = mapper.writeValueAsString(java.util.Map.of(
                    "url", webhookUrl, "secret_token", webhookSecret));
            http.send(HttpRequest.newBuilder(URI.create("https://api.telegram.org/bot" + botToken + "/setWebhook"))
                    .header("Content-Type", "application/json").POST(HttpRequest.BodyPublishers.ofString(body)).build(),
                    HttpResponse.BodyHandlers.discarding());
        } catch (Exception ignored) { /* API remains usable; configure the webhook after deployment if needed. */ }
    }

    @Transactional
    public LinkResponse issueLink(String authorization) {
        Technician tech = currentTechnician(authorization);
        byte[] bytes = new byte[24]; random.nextBytes(bytes);
        String code = HexFormat.of().formatHex(bytes);
        TelegramLinkCode row = new TelegramLinkCode();
        row.setCode(code); row.setTechnicianId(tech.getTechnicianId());
        row.setExpiresAt(LocalDateTime.now().plusMinutes(10)); codes.save(row);
        return new LinkResponse("https://t.me/" + botUsername + "?start=" + code,
                row.getExpiresAt().toString());
    }

    @Transactional(readOnly = true)
    public WalletResponse myWallet(String authorization) {
        Technician tech = currentTechnician(authorization);
        return walletResponse(tech.getTechnicianId());
    }

    @Transactional
    public void credit(Payment payment, Long technicianId) {
        if (payment == null || technicianId == null || payment.getBaseAmount() == null
                || payment.getBaseAmount() <= 0 || wallet.existsByPaymentId(payment.getId())) return;
        TechnicianWalletEntry entry = new TechnicianWalletEntry();
        entry.setTechnicianId(technicianId); entry.setPaymentId(payment.getId());
        entry.setJobId(payment.getJobId()); entry.setAmount(payment.getBaseAmount());
        wallet.save(entry);
        links.findByTechnicianId(technicianId).ifPresent(link -> send(link.getChatId(),
                "Payment received for booking #" + payment.getJobId() + ". Wallet credited: $"
                        + money(payment.getBaseAmount()) + " USD. Balance: $"
                        + money(wallet.balance(technicianId)) + " USD."));
    }

    /** Telegram webhook entry point. Link codes expire after ten minutes and are single-use. */
    @Transactional
    public void acceptUpdate(String headerSecret, JsonNode update) {
        if (webhookSecret.isBlank() || !constantTimeEquals(webhookSecret, headerSecret))
            throw new ResponseStatusException(UNAUTHORIZED);
        JsonNode message = update == null ? null : update.path("message");
        if (message == null || message.isMissingNode()) return;
        String chatId = message.path("chat").path("id").asText("");
        String userId = message.path("from").path("id").asText("");
        String text = message.path("text").asText("").trim();
        if (chatId.isBlank() || text.isBlank()) return;
        if (text.startsWith("/start")) {
            String[] parts = text.split("\\s+", 2);
            if (parts.length == 2) {
                TelegramLinkCode code = codes.findById(parts[1]).orElse(null);
                if (code == null || code.getExpiresAt().isBefore(LocalDateTime.now())) {
                    send(chatId, "That account link expired. Generate a fresh link in the CamFix technician app.");
                } else {
                    links.findByTechnicianId(code.getTechnicianId()).ifPresent(links::delete);
                    links.findByChatId(chatId).ifPresent(links::delete);
                    TelegramTechnicianLink link = new TelegramTechnicianLink();
                    link.setTechnicianId(code.getTechnicianId()); link.setChatId(chatId);
                    link.setTelegramUserId(userId); links.save(link); codes.delete(code);
                    send(chatId, "Your CamFix technician account is linked. Use /balance to check earnings.");
                }
            } else send(chatId, "Welcome to CamFix technician wallet. Link your account from the technician app.");
        } else if (text.startsWith("/balance")) {
            links.findByChatId(chatId).ifPresentOrElse(link -> {
                WalletResponse current = walletResponse(link.getTechnicianId());
                send(chatId, "Available wallet balance: $" + money(current.balance()) + " USD.");
            }, () -> send(chatId, "Link your technician account first from the CamFix technician app."));
        } else if (text.startsWith("/help")) send(chatId, "Commands: /balance — check your CamFix earnings.");
    }

    private Technician currentTechnician(String authorization) {
        String token = authorization == null ? null : authorization.replaceFirst("(?i)^Bearer\\s+", "").trim();
        String email = jwt.extractEmail(token);
        if (email == null) throw new IllegalArgumentException("Not authenticated");
        Users user = users.findByEmail(email).orElseThrow(() -> new IllegalArgumentException("User not found"));
        return technicians.findByUsers_UserId(user.getUserId())
                .orElseThrow(() -> new NoSuchElementException("No technician profile for this account"));
    }

    private WalletResponse walletResponse(Long technicianId) {
        Double balance = wallet.balance(technicianId);
        return new WalletResponse(balance == null ? 0 : balance,
                links.findByTechnicianId(technicianId).isPresent());
    }
    private void send(String chatId, String text) {
        if (botToken.isBlank()) return;
        try {
            String body = mapper.writeValueAsString(java.util.Map.of("chat_id", chatId, "text", text));
            http.send(HttpRequest.newBuilder(URI.create("https://api.telegram.org/bot" + botToken + "/sendMessage"))
                    .header("Content-Type", "application/json").POST(HttpRequest.BodyPublishers.ofString(body)).build(),
                    HttpResponse.BodyHandlers.discarding());
        } catch (Exception ignored) { /* wallet ledger remains authoritative when Telegram is unavailable */ }
    }
    private static String money(Double value) { return String.format(java.util.Locale.ROOT, "%.2f", value == null ? 0 : value); }
    private static boolean constantTimeEquals(String a, String b) {
        if (a == null || b == null || a.length() != b.length()) return false;
        int diff = 0; for (int i = 0; i < a.length(); i++) diff |= a.charAt(i) ^ b.charAt(i);
        return diff == 0;
    }
    public record LinkResponse(String link, String expiresAt) { }
    public record WalletResponse(double balance, boolean telegramLinked) { }
}
