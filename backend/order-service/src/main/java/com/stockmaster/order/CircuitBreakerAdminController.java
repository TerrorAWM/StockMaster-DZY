package com.stockmaster.order;

import com.stockmaster.common.ApiResponse;
import io.github.resilience4j.circuitbreaker.CircuitBreaker;
import io.github.resilience4j.circuitbreaker.CircuitBreakerRegistry;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

/**
 * 手动熔断管理接口。
 * 经网关 StripPrefix=1 后访问路径为 /api/orders/admin/circuit-breakers/**。
 * 用于演示：不停服务即可强制熔断器打开/复位，配合监控面板的开关。
 */
@RestController
@RequestMapping("/orders/admin/circuit-breakers")
public class CircuitBreakerAdminController {

    /** 与 RemoteServiceGateway 中 @CircuitBreaker 的实例名保持一致。 */
    private static final List<String> MANAGED = List.of("productService", "stockService");

    private final CircuitBreakerRegistry registry;

    public CircuitBreakerAdminController(CircuitBreakerRegistry registry) {
        this.registry = registry;
    }

    /** 列出所有受管熔断器的当前状态与指标。 */
    @GetMapping
    public ApiResponse<List<Map<String, Object>>> list() {
        List<Map<String, Object>> data = MANAGED.stream()
                .map(name -> describe(registry.circuitBreaker(name)))
                .toList();
        return ApiResponse.ok(data);
    }

    /** 强制打开熔断器：之后所有调用被直接拒绝，触发降级。 */
    @PostMapping("/{name}/force-open")
    public ApiResponse<Map<String, Object>> forceOpen(@PathVariable String name) {
        CircuitBreaker cb = registry.circuitBreaker(name);
        cb.transitionToForcedOpenState();
        return ApiResponse.ok(describe(cb));
    }

    /** 复位熔断器：回到 CLOSED 并清空统计。 */
    @PostMapping("/{name}/reset")
    public ApiResponse<Map<String, Object>> reset(@PathVariable String name) {
        CircuitBreaker cb = registry.circuitBreaker(name);
        cb.reset();
        return ApiResponse.ok(describe(cb));
    }

    private Map<String, Object> describe(CircuitBreaker cb) {
        CircuitBreaker.Metrics m = cb.getMetrics();
        return Map.of(
                "name", cb.getName(),
                "state", cb.getState().name(),
                "failureRate", m.getFailureRate(),
                "bufferedCalls", m.getNumberOfBufferedCalls(),
                "failedCalls", m.getNumberOfFailedCalls(),
                "notPermittedCalls", m.getNumberOfNotPermittedCalls()
        );
    }
}
