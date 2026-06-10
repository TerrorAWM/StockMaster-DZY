package com.stockmaster.gateway;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class RateLimitGatewayFilterTest {
    @Test
    void rejectsRequestsAfterCapacityIsConsumed() {
        RateLimitGatewayFilter.TokenBucket bucket = new RateLimitGatewayFilter.TokenBucket(2, 0);

        assertTrue(bucket.tryConsume());
        assertTrue(bucket.tryConsume());
        assertFalse(bucket.tryConsume());
    }
}
