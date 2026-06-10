package com.stockmaster.order;

import com.stockmaster.common.ApiResponse;
import io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker;
import org.springframework.stereotype.Service;

import java.util.Map;

@Service
public class RemoteServiceGateway {
    private final ProductClient products;
    private final StockClient stocks;

    public RemoteServiceGateway(ProductClient products, StockClient stocks) {
        this.products = products;
        this.stocks = stocks;
    }

    @CircuitBreaker(name = "productService", fallbackMethod = "productFallback")
    public ApiResponse<Map<String, Object>> getProduct(Long productId) {
        return products.get(productId);
    }

    @CircuitBreaker(name = "stockService", fallbackMethod = "stockFallback")
    public ApiResponse<Map<String, Object>> changeStock(StockClient.ChangeStockRequest request) {
        return stocks.change(request);
    }

    private ApiResponse<Map<String, Object>> productFallback(Long productId, Throwable error) {
        return ApiResponse.fail("商品服务暂时不可用，已触发熔断降级");
    }

    private ApiResponse<Map<String, Object>> stockFallback(StockClient.ChangeStockRequest request, Throwable error) {
        return ApiResponse.fail("库存服务暂时不可用，已触发熔断降级");
    }
}
