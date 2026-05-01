package com.example.template.order.infrastructure;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;

import java.math.BigDecimal;
import java.util.UUID;

@Embeddable
public class OrderItemJpaEntity {

    @Column(name = "product_id", nullable = false)
    private UUID productId;

    @Column(name = "quantity", nullable = false)
    private int quantity;

    @Column(name = "price_amount", nullable = false, precision = 19, scale = 2)
    private BigDecimal priceAmount;

    @Column(name = "price_currency", nullable = false, length = 3)
    private String priceCurrency;

    protected OrderItemJpaEntity() {}

    public OrderItemJpaEntity(UUID productId, int quantity, BigDecimal priceAmount, String priceCurrency) {
        this.productId = productId;
        this.quantity = quantity;
        this.priceAmount = priceAmount;
        this.priceCurrency = priceCurrency;
    }

    public UUID getProductId() { return productId; }
    public int getQuantity() { return quantity; }
    public BigDecimal getPriceAmount() { return priceAmount; }
    public String getPriceCurrency() { return priceCurrency; }
}
