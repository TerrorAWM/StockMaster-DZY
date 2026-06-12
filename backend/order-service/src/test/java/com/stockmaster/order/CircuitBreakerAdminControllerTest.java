package com.stockmaster.order;

import io.github.resilience4j.circuitbreaker.CircuitBreaker;
import io.github.resilience4j.circuitbreaker.CircuitBreakerRegistry;
import org.junit.jupiter.api.Test;
import org.springframework.web.server.ResponseStatusException;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

class CircuitBreakerAdminControllerTest {
    private final CircuitBreakerRegistry registry = CircuitBreakerRegistry.ofDefaults();
    private final CircuitBreakerAdminController controller = new CircuitBreakerAdminController(registry);

    @Test
    void adminCanForceOpenAndResetCircuitBreaker() {
        controller.forceOpen("admin", "productService");

        assertEquals(CircuitBreaker.State.FORCED_OPEN, registry.circuitBreaker("productService").getState());

        controller.reset("admin", "productService");

        assertEquals(CircuitBreaker.State.CLOSED, registry.circuitBreaker("productService").getState());
    }

    @Test
    void nonAdminCannotChangeCircuitBreaker() {
        assertThrows(ResponseStatusException.class, () -> controller.forceOpen("staff", "productService"));
    }

    @Test
    void unknownCircuitBreakerCannotBeCreated() {
        assertThrows(ResponseStatusException.class, () -> controller.forceOpen("admin", "unknown"));
    }
}
