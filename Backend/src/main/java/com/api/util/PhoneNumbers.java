package com.api.util;

/**
 * Canonical phone form used everywhere a {@code Users.phoneNumber} is written,
 * so every write path produces the same key that phone-OTP lookups search by.
 * "+855 97 8068 525", "097 8068 525" and "+855978068525" all collapse to
 * "+855978068525".
 */
public final class PhoneNumbers {

    private PhoneNumbers() {
    }

    public static String canonicalize(String raw) {
        String trimmed = raw.trim();
        String digits = trimmed.replaceAll("\\D", "");
        if (trimmed.startsWith("+")) {
            return "+" + digits;
        }
        if (digits.startsWith("0")) {
            // Local Cambodian trunk prefix: "097 8068 525" -> "+855978068525".
            return "+855" + digits.substring(1);
        }
        return "+" + digits;
    }
}
