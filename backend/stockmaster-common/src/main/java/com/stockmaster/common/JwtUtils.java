package com.stockmaster.common;

import com.fasterxml.jackson.databind.ObjectMapper;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.Base64;

public final class JwtUtils {
    private static final ObjectMapper MAPPER = new ObjectMapper();
    private static final Base64.Encoder URL_ENCODER = Base64.getUrlEncoder().withoutPadding();
    private static final Base64.Decoder URL_DECODER = Base64.getUrlDecoder();

    private JwtUtils() {
    }

    public static String createToken(Long userId, String username, String role, String secret, Duration ttl) {
        try {
            String header = URL_ENCODER.encodeToString("{\"alg\":\"HS256\",\"typ\":\"JWT\"}".getBytes(StandardCharsets.UTF_8));
            JwtClaims claims = new JwtClaims(userId, username, role, System.currentTimeMillis() + ttl.toMillis());
            String payload = URL_ENCODER.encodeToString(MAPPER.writeValueAsBytes(claims));
            String body = header + "." + payload;
            return body + "." + sign(body, secret);
        } catch (Exception ex) {
            throw new IllegalStateException("Unable to create JWT", ex);
        }
    }

    public static JwtClaims verify(String token, String secret) {
        try {
            String[] parts = token.split("\\.");
            if (parts.length != 3) {
                throw new IllegalArgumentException("Invalid token");
            }
            String body = parts[0] + "." + parts[1];
            if (!constantTimeEquals(parts[2], sign(body, secret))) {
                throw new IllegalArgumentException("Invalid signature");
            }
            JwtClaims claims = MAPPER.readValue(URL_DECODER.decode(parts[1]), JwtClaims.class);
            if (claims.expired()) {
                throw new IllegalArgumentException("Token expired");
            }
            return claims;
        } catch (Exception ex) {
            throw new IllegalArgumentException("Invalid token", ex);
        }
    }

    private static String sign(String body, String secret) throws Exception {
        Mac mac = Mac.getInstance("HmacSHA256");
        mac.init(new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
        return URL_ENCODER.encodeToString(mac.doFinal(body.getBytes(StandardCharsets.UTF_8)));
    }

    private static boolean constantTimeEquals(String left, String right) {
        if (left.length() != right.length()) {
            return false;
        }
        int result = 0;
        for (int i = 0; i < left.length(); i++) {
            result |= left.charAt(i) ^ right.charAt(i);
        }
        return result == 0;
    }
}

