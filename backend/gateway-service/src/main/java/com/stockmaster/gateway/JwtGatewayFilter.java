package com.stockmaster.gateway;

import com.stockmaster.common.JwtClaims;
import com.stockmaster.common.JwtUtils;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.core.Ordered;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

@Component
public class JwtGatewayFilter implements GlobalFilter, Ordered {
    @Value("${stockmaster.jwt.secret:stockmaster-dev-secret}")
    private String jwtSecret;

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        String path = exchange.getRequest().getURI().getPath();
        if (path.equals("/api/auth/login") || path.startsWith("/actuator") || path.startsWith("/eureka")) {
            return chain.filter(exchange);
        }
        String auth = exchange.getRequest().getHeaders().getFirst(HttpHeaders.AUTHORIZATION);
        if (auth == null || !auth.startsWith("Bearer ")) {
            exchange.getResponse().setStatusCode(HttpStatus.UNAUTHORIZED);
            return exchange.getResponse().setComplete();
        }
        try {
            JwtClaims claims = JwtUtils.verify(auth.substring(7), jwtSecret);
            ServerWebExchange mutated = exchange.mutate()
                    .request(builder -> builder
                            .header("X-User-Id", String.valueOf(claims.userId()))
                            .header("X-Username", claims.username())
                            .header("X-Role", claims.role()))
                    .build();
            return chain.filter(mutated);
        } catch (IllegalArgumentException ex) {
            exchange.getResponse().setStatusCode(HttpStatus.UNAUTHORIZED);
            return exchange.getResponse().setComplete();
        }
    }

    @Override
    public int getOrder() {
        return -100;
    }
}

