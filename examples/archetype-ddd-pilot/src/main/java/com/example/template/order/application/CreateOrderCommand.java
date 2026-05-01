package com.example.template.order.application;

import com.example.template.order.domain.OrderItem;

import java.util.List;
import java.util.Objects;

public record CreateOrderCommand(List<OrderItem> items) {

    public CreateOrderCommand {
        Objects.requireNonNull(items, "items must not be null");
        items = List.copyOf(items);
    }
}
