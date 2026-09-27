package com.api.Service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.math.BigDecimal;
import java.util.LinkedHashMap;
import java.util.Map;

import org.junit.jupiter.api.Test;

class KhqrCodecTest {

    /** Standard CRC-16/CCITT-FALSE check value. */
    @Test
    void crcMatchesKnownVector() {
        assertEquals("29B1", KhqrCodec.crc16("123456789"));
    }

    @Test
    void buildsValidTlvWithCorrectCrc() {
        String qr = KhqrCodec.build("camfix@aclb", "CAMFIX", "Phnom Penh",
                new BigDecimal("12.5"), "CF21-7", 1790000000000L, 1790000300000L);

        // Walk the top-level TLVs.
        Map<String, String> tags = new LinkedHashMap<>();
        int i = 0;
        while (i < qr.length()) {
            String tag = qr.substring(i, i + 2);
            int len = Integer.parseInt(qr.substring(i + 2, i + 4));
            tags.put(tag, qr.substring(i + 4, i + 4 + len));
            i += 4 + len;
        }
        assertEquals("01", tags.get("00"));
        assertEquals("12", tags.get("01"));
        assertEquals("0011camfix@aclb", tags.get("29"));
        assertEquals("840", tags.get("53"));
        assertEquals("12.50", tags.get("54"));
        assertEquals("KH", tags.get("58"));
        assertEquals("CAMFIX", tags.get("59"));
        assertEquals("Phnom Penh", tags.get("60"));
        assertEquals("0106CF21-7", tags.get("62"));
        assertEquals("00131790000000000" + "01131790000300000", tags.get("99"));

        // CRC covers everything up to and including "6304".
        String crc = tags.get("63");
        assertEquals(KhqrCodec.crc16(qr.substring(0, qr.length() - 4)), crc);
        assertTrue(qr.endsWith("6304" + crc));
        assertEquals(32, KhqrCodec.md5(qr).length());
    }
}
