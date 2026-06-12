package com.stockmaster.order;

import com.stockmaster.common.ApiResponse;
import io.github.resilience4j.circuitbreaker.CircuitBreaker;
import io.github.resilience4j.circuitbreaker.CircuitBreakerRegistry;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

@RestController
@RequestMapping("/orders/admin/circuit-breakers")
public class CircuitBreakerAdminController {
    private static final Set<String> MANAGED_CIRCUIT_BREAKERS = Set.of("productService", "stockService");

    private final CircuitBreakerRegistry registry;

    public CircuitBreakerAdminController(CircuitBreakerRegistry registry) {
        this.registry = registry;
    }

    @GetMapping
    public ApiResponse<List<Map<String, Object>>> list(@RequestHeader("X-Role") String role) {
        requireAdmin(role);
        return ApiResponse.ok(MANAGED_CIRCUIT_BREAKERS.stream()
                .sorted()
                .map(this::snapshot)
                .toList());
    }

    @PostMapping("/{name}/force-open")
    public ApiResponse<Map<String, Object>> forceOpen(
            @RequestHeader("X-Role") String role,
            @PathVariable("name") String name) {
        requireAdmin(role);
        CircuitBreaker circuitBreaker = managedCircuitBreaker(name);
        circuitBreaker.transitionToForcedOpenState();
        return ApiResponse.ok(snapshot(circuitBreaker));
    }

    @PostMapping("/{name}/reset")
    public ApiResponse<Map<String, Object>> reset(
            @RequestHeader("X-Role") String role,
            @PathVariable("name") String name) {
        requireAdmin(role);
        CircuitBreaker circuitBreaker = managedCircuitBreaker(name);
        circuitBreaker.reset();
        return ApiResponse.ok(snapshot(circuitBreaker));
    }

    private Map<String, Object> snapshot(String name) {
        return snapshot(managedCircuitBreaker(name));
    }

    private Map<String, Object> snapshot(CircuitBreaker circuitBreaker) {
        CircuitBreaker.Metrics metrics = circuitBreaker.getMetrics();
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("name", circuitBreaker.getName());
        result.put("state", circuitBreaker.getState().name());
        result.put("failureRate", metrics.getFailureRate());
        result.put("bufferedCalls", metrics.getNumberOfBufferedCalls());
        result.put("failedCalls", metrics.getNumberOfFailedCalls());
        result.put("notPermittedCalls", metrics.getNumberOfNotPermittedCalls());
        return result;
    }

    private CircuitBreaker managedCircuitBreaker(String name) {
        if (!MANAGED_CIRCUIT_BREAKERS.contains(name)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "未知熔断器: " + name);
        }
        return registry.circuitBreaker(name);
    }

    private void requireAdmin(String role) {
        if (!"admin".equals(role)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "仅管理员可操作熔断器");
        }
    }
}
