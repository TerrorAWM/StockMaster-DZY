package com.stockmaster.stock;

import com.stockmaster.common.ApiResponse;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
public class StockController {
    private final StockRepository stocks;
    private final ProductClient products;

    public StockController(StockRepository stocks, ProductClient products) {
        this.stocks = stocks;
        this.products = products;
    }

    @GetMapping("/stock")
    public ApiResponse<List<StockItem>> list() {
        return ApiResponse.ok(stocks.findAll());
    }

    @PostMapping("/stock/change")
    @Transactional
    public ApiResponse<StockItem> change(@RequestBody ChangeStockRequest request) {
        ApiResponse<Map<String, Object>> product = products.get(request.productId());
        if (product.code() != 0 || product.data() == null) {
            return ApiResponse.fail("商品不存在");
        }
        StockItem item = stocks.findByProductId(request.productId()).orElseGet(() -> {
            StockItem created = new StockItem();
            created.setProductId(request.productId());
            created.setQuantity(0);
            return created;
        });
        int next = item.getQuantity() + request.delta();
        if (next < 0) {
            return ApiResponse.fail("库存不足");
        }
        item.setQuantity(next);
        return ApiResponse.ok(stocks.save(item));
    }

    @GetMapping("/stock/warnings")
    public ApiResponse<List<Map<String, Object>>> warnings() {
        List<Map<String, Object>> result = stocks.findAll().stream()
                .map(item -> {
                    ApiResponse<Map<String, Object>> product = products.get(item.getProductId());
                    Map<String, Object> productData = product.data();
                    int threshold = productData == null ? 0 : ((Number) productData.getOrDefault("warningThreshold", 0)).intValue();
                    if (item.getQuantity() >= threshold) {
                        return null;
                    }
                    return Map.of("productId", item.getProductId(), "quantity", item.getQuantity(), "warningThreshold", threshold, "product", productData);
                })
                .filter(v -> v != null)
                .toList();
        return ApiResponse.ok(result);
    }

    public record ChangeStockRequest(Long productId, Integer delta) {}
}

