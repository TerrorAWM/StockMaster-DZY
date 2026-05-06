package com.stockmaster.order;

import com.stockmaster.common.ApiResponse;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;

import java.util.Map;

@FeignClient(name = "stock-service")
public interface StockClient {
    @PostMapping("/stock/change")
    ApiResponse<Map<String, Object>> change(@RequestBody ChangeStockRequest request);
    record ChangeStockRequest(Long productId, Integer delta) {}
}

