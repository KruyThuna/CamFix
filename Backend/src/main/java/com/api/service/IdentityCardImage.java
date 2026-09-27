package com.api.service;

import java.io.ByteArrayInputStream;
import java.util.Base64;
import javax.imageio.ImageIO;
import javax.imageio.stream.ImageInputStream;

/** Validates identity documents before any registration records are written. */
public final class IdentityCardImage {
    private IdentityCardImage() {}
    private static final int MAX_BYTES = 5 * 1024 * 1024;

    public static byte[] decode(String encoded, String label) {
        try {
            return decode(encoded);
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException(e.getMessage().replace("ID card", label));
        }
    }

    public static byte[] decode(String encoded) {
        if (encoded == null || encoded.isBlank()) {
            throw new IllegalArgumentException("ID card photo is required");
        }
        if (encoded.length() > 4 * ((MAX_BYTES + 2) / 3)) {
            throw new IllegalArgumentException("ID card photo must be no larger than 5 MB");
        }
        byte[] bytes;
        try {
            bytes = Base64.getDecoder().decode(encoded);
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("Invalid ID card image encoding");
        }
        if (bytes.length > MAX_BYTES) {
            throw new IllegalArgumentException("ID card photo must be no larger than 5 MB");
        }
        contentType(bytes);
        try (ImageInputStream input = ImageIO.createImageInputStream(new ByteArrayInputStream(bytes))) {
            var readers = ImageIO.getImageReaders(input);
            if (!readers.hasNext()) throw new IllegalArgumentException("Invalid ID card image");
            var reader = readers.next();
            try {
                reader.setInput(input);
                int width = reader.getWidth(0), height = reader.getHeight(0);
                if (width < 1 || height < 1 || (long) width * height > 20_000_000) {
                    throw new IllegalArgumentException("ID card image exceeds 20 megapixels");
                }
                reader.read(0);
            } finally {
                reader.dispose();
            }
        } catch (java.io.IOException e) {
            throw new IllegalArgumentException("Invalid ID card image");
        }
        return bytes;
    }

    public static String contentType(byte[] bytes) {
        if (bytes.length >= 3 && (bytes[0] & 255) == 255 && (bytes[1] & 255) == 216
                && (bytes[2] & 255) == 255) return "image/jpeg";
        byte[] png = {(byte) 137, 80, 78, 71, 13, 10, 26, 10};
        if (bytes.length >= png.length && java.util.Arrays.equals(png,
                java.util.Arrays.copyOf(bytes, png.length))) return "image/png";
        throw new IllegalArgumentException("ID card photo must be a JPEG or PNG image");
    }
}
