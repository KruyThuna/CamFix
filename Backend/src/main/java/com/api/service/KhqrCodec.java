package com.api.service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;

/**
 * Builds a dynamic individual KHQR string (Bakong's EMVCo merchant-presented
 * QR profile) and its MD5 - the MD5 is what Bakong's
 * {@code /v1/check_transaction_by_md5} looks transactions up by.
 *
 * Tag layout (EMVCo TLV, 2-digit tag + 2-digit length + value):
 * 00 payload format "01" · 01 point of initiation "12" (dynamic) ·
 * 29 individual account (00 Bakong account id) · 52 MCC · 53 currency ·
 * 54 amount · 58 "KH" · 59 merchant name · 60 merchant city ·
 * 62 additional data (01 bill number) · 99 timestamps (00 created, 01 expires,
 * epoch ms) · 63 CRC-16/CCITT-FALSE over everything up to and incl. "6304".
 */
public final class KhqrCodec {

    public static final String CURRENCY_USD = "840";

    private KhqrCodec() {
    }

    public static String build(String bakongAccountId, String merchantName, String merchantCity,
            BigDecimal amountUsd, String billNumber, long createdMs, long expiresMs) {
        StringBuilder sb = new StringBuilder();
        sb.append(tlv("00", "01"));
        sb.append(tlv("01", "12"));
        sb.append(tlv("29", tlv("00", bakongAccountId)));
        sb.append(tlv("52", "5999"));
        sb.append(tlv("53", CURRENCY_USD));
        sb.append(tlv("54", amountUsd.setScale(2, RoundingMode.HALF_UP).toPlainString()));
        sb.append(tlv("58", "KH"));
        sb.append(tlv("59", clip(merchantName, 25)));
        sb.append(tlv("60", clip(merchantCity, 15)));
        if (billNumber != null && !billNumber.isBlank()) {
            sb.append(tlv("62", tlv("01", clip(billNumber, 25))));
        }
        sb.append(tlv("99", tlv("00", Long.toString(createdMs)) + tlv("01", Long.toString(expiresMs))));
        sb.append("6304");
        sb.append(crc16(sb.toString()));
        return sb.toString();
    }

    public static String md5(String s) {
        try {
            MessageDigest md = MessageDigest.getInstance("MD5");
            return HexFormat.of().formatHex(md.digest(s.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        }
    }

    /** CRC-16/CCITT-FALSE (poly 0x1021, init 0xFFFF), 4 uppercase hex chars. */
    static String crc16(String s) {
        int crc = 0xFFFF;
        for (byte b : s.getBytes(StandardCharsets.UTF_8)) {
            crc ^= (b & 0xFF) << 8;
            for (int i = 0; i < 8; i++) {
                crc = (crc & 0x8000) != 0 ? (crc << 1) ^ 0x1021 : crc << 1;
                crc &= 0xFFFF;
            }
        }
        return String.format("%04X", crc);
    }

    private static String tlv(String tag, String value) {
        int len = value.getBytes(StandardCharsets.UTF_8).length;
        if (len > 99) {
            throw new IllegalArgumentException("KHQR field " + tag + " is too long");
        }
        return tag + String.format("%02d", len) + value;
    }

    private static String clip(String s, int max) {
        String v = s == null ? "" : s.trim();
        return v.length() <= max ? v : v.substring(0, max);
    }
}
