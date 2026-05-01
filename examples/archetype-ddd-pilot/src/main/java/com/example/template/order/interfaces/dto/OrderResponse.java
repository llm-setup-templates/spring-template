package com.example.template.order.interfaces.dto;

import com.example.template.order.domain.Money;
import com.example.template.order.domain.Order;
import com.example.template.order.domain.OrderStatus;

import java.time.Instant;
import java.util.UUID;

public record OrderResponse(
    UUID id,
    Money total,    // Jackson default: { amount, currency } nested object (R4 R4-M2/CX-31)
    OrderStatus status,
    Instant createdAt,
    int itemCount,
    Long version
) {
    public static OrderResponse from(Order order) {
        return new OrderResponse(
            order.getId().value(),
            order.getTotal(),
            order.getStatus(),
            order.getCreatedAt(),
            order.getItems().size(),
            order.getVersion()
        );
    }
}
