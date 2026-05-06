package com.stockmaster.product;

import com.stockmaster.common.ApiResponse;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
public class ProductController {
    private final ProductRepository products;

    public ProductController(ProductRepository products) {
        this.products = products;
    }

    @GetMapping("/products")
    public ApiResponse<List<Product>> list() {
        return ApiResponse.ok(products.findAll());
    }

    @GetMapping("/products/{id}")
    public ApiResponse<Product> get(@PathVariable Long id) {
        return products.findById(id).map(ApiResponse::ok).orElseGet(() -> ApiResponse.fail("商品不存在"));
    }

    @PostMapping("/products")
    public ApiResponse<Product> create(@RequestHeader("X-Role") String role, @RequestBody Product product) {
        if (!"admin".equals(role)) {
            return ApiResponse.fail("无权限");
        }
        if (products.existsBySku(product.getSku())) {
            return ApiResponse.fail("SKU 已存在");
        }
        product.setId(null);
        return ApiResponse.ok(products.save(product));
    }

    @PutMapping("/products/{id}")
    public ApiResponse<Product> update(@RequestHeader("X-Role") String role, @PathVariable Long id, @RequestBody Product request) {
        if (!"admin".equals(role)) {
            return ApiResponse.fail("无权限");
        }
        Product product = products.findById(id).orElse(null);
        if (product == null) {
            return ApiResponse.fail("商品不存在");
        }
        product.setName(request.getName());
        product.setCategory(request.getCategory());
        product.setUnit(request.getUnit());
        product.setWarningThreshold(request.getWarningThreshold());
        product.setEnabled(request.isEnabled());
        return ApiResponse.ok(products.save(product));
    }
}

