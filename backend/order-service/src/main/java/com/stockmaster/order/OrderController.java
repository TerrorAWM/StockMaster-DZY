package com.stockmaster.order;

import com.stockmaster.common.ApiResponse;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
public class OrderController {
    private final OrderRepository orders;
    private final ProductClient products;
    private final StockClient stocks;

    public OrderController(OrderRepository orders, ProductClient products, StockClient stocks) {
        this.orders = orders;
        this.products = products;
        this.stocks = stocks;
    }

    @GetMapping("/orders")
    public ApiResponse<List<StockOrder>> list() {
        return ApiResponse.ok(orders.findAll());
    }

    @PostMapping("/orders/inbound")
    @Transactional
    public ApiResponse<StockOrder> inbound(@RequestHeader("X-Username") String username, @RequestBody OrderRequest request) {
        return create(username, "INBOUND", request);
    }

    @PostMapping("/orders/outbound")
    @Transactional
    public ApiResponse<StockOrder> outbound(@RequestHeader("X-Username") String username, @RequestBody OrderRequest request) {
        return create(username, "OUTBOUND", request);
    }

    private ApiResponse<StockOrder> create(String username, String type, OrderRequest request) {
        if (request.quantity() == null || request.quantity() <= 0) {
            return ApiResponse.fail("数量必须大于 0");
        }
        ApiResponse<Map<String, Object>> product = products.get(request.productId());
        if (product.code() != 0 || product.data() == null) {
            return ApiResponse.fail("商品不存在");
        }
        int delta = "INBOUND".equals(type) ? request.quantity() : -request.quantity();
        ApiResponse<Map<String, Object>> changed = stocks.change(new StockClient.ChangeStockRequest(request.productId(), delta));
        if (changed.code() != 0) {
            return ApiResponse.fail(changed.message());
        }
        StockOrder order = new StockOrder();
        order.setProductId(request.productId());
        order.setType(type);
        order.setQuantity(request.quantity());
        order.setOperator(username);
        order.setRemark(request.remark());
        return ApiResponse.ok(orders.save(order));
    }

    public record OrderRequest(Long productId, Integer quantity, String remark) {}
}

