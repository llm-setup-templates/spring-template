package com.example.template.order.domain;

import org.jmolecules.ddd.annotation.Entity;

import java.util.Objects;
import java.util.UUID;

@Entity
public final class OrderItem {

    private final UUID productId;
    private final int quantity;
    private final Money price;

    public OrderItem(UUID productId, int quantity, Money price) {
        Objects.requireNonNull(productId, "productId must not be null");
        Objects.requireNonNull(price, "price must not be null");
        if (quantity <= 0) {
            throw new IllegalArgumentException("quantity must be positive: " + quantity);
        }
        this.productId = productId;
        this.quantity = quantity;
        this.price = price;
    }

    public Money lineTotal() {
        return price.multiply(quantity);
    }

    public UUID getProductId() { return productId; }
    public int getQuantity() { return quantity; }
    public Money getPrice() { return price; }
}
