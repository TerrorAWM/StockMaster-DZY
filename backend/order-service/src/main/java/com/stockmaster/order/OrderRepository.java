package com.stockmaster.order;

import org.springframework.data.jpa.repository.JpaRepository;

public interface OrderRepository extends JpaRepository<StockOrder, Long> {
}

