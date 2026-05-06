package com.stockmaster.common;

public record JwtClaims(Long userId, String username, String role, long expiresAt) {
    public boolean expired() {
        return System.currentTimeMillis() > expiresAt;
    }
}

