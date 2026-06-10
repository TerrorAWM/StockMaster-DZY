package com.stockmaster.gateway;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.core.Ordered;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

import java.nio.charset.StandardCharsets;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Component
public class RateLimitGatewayFilter implements GlobalFilter, Ordered {
    private final Map<String, TokenBucket> buckets = new ConcurrentHashMap<>();

    @Value("${stockmaster.rate-limit.capacity:30}")
    private int capacity;

    @Value("${stockmaster.rate-limit.refill-per-second:10}")
    private int refillPerSecond;

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        if (exchange.getRequest().getURI().getPath().startsWith("/actuator")) {
            return chain.filter(exchange);
        }

        String forwardedFor = exchange.getRequest().getHeaders().getFirst("X-Forwarded-For");
        String client = forwardedFor == null || forwardedFor.isBlank()
                ? remoteAddress(exchange)
                : forwardedFor.split(",")[0].trim();
        TokenBucket bucket = buckets.computeIfAbsent(client, ignored -> new TokenBucket(capacity, refillPerSecond));
        if (bucket.tryConsume()) {
            exchange.getResponse().getHeaders().set("X-RateLimit-Limit", String.valueOf(capacity));
            return chain.filter(exchange);
        }

        exchange.getResponse().setStatusCode(HttpStatus.TOO_MANY_REQUESTS);
        exchange.getResponse().getHeaders().set("Content-Type", "application/json;charset=UTF-8");
        byte[] body = "{\"code\":429,\"message\":\"请求过于频繁，已触发网关限流\",\"data\":null}"
                .getBytes(StandardCharsets.UTF_8);
        return exchange.getResponse().writeWith(Mono.just(exchange.getResponse().bufferFactory().wrap(body)));
    }

    @Override
    public int getOrder() {
        return -200;
    }

    private String remoteAddress(ServerWebExchange exchange) {
        return exchange.getRequest().getRemoteAddress() == null
                ? "unknown"
                : exchange.getRequest().getRemoteAddress().getAddress().getHostAddress();
    }

    static final class TokenBucket {
        private final int capacity;
        private final int refillPerSecond;
        private double tokens;
        private long lastRefillNanos;

        TokenBucket(int capacity, int refillPerSecond) {
            this.capacity = capacity;
            this.refillPerSecond = refillPerSecond;
            this.tokens = capacity;
            this.lastRefillNanos = System.nanoTime();
        }

        synchronized boolean tryConsume() {
            long now = System.nanoTime();
            double elapsedSeconds = (now - lastRefillNanos) / 1_000_000_000.0;
            tokens = Math.min(capacity, tokens + elapsedSeconds * refillPerSecond);
            lastRefillNanos = now;
            if (tokens < 1) {
                return false;
            }
            tokens -= 1;
            return true;
        }
    }
}
