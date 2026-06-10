package com.stockmaster.common;

import org.junit.jupiter.api.Test;

import java.time.Duration;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

class JwtUtilsTest {
    @Test
    void createsAndVerifiesToken() {
        String token = JwtUtils.createToken(7L, "admin", "admin", "test-secret", Duration.ofMinutes(1));

        JwtClaims claims = JwtUtils.verify(token, "test-secret");

        assertEquals(7L, claims.userId());
        assertEquals("admin", claims.username());
        assertEquals("admin", claims.role());
    }

    @Test
    void rejectsTokenSignedWithDifferentSecret() {
        String token = JwtUtils.createToken(7L, "admin", "admin", "test-secret", Duration.ofMinutes(1));

        assertThrows(IllegalArgumentException.class, () -> JwtUtils.verify(token, "wrong-secret"));
    }
}
