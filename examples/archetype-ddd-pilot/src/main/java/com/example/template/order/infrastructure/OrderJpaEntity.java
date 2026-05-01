package com.example.template.order.infrastructure;

import com.example.template.order.domain.Money;
import com.example.template.order.domain.Order;
import com.example.template.order.domain.OrderId;
import com.example.template.order.domain.OrderItem;
import com.example.template.order.domain.OrderStatus;

import jakarta.persistence.CollectionTable;
import jakarta.persistence.Column;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.Table;
import jakarta.persistence.Version;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "orders")
public class OrderJpaEntity {

    @Id
    @Column(name = "id", updatable = false, nullable = false)
    private UUID id;

    @Version // R1 C-05 / CX-3: optimistic lock support
    @Column(name = "version")
    private Long version;

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "order_items",
        joinColumns = @JoinColumn(name = "order_id"))
    private List<OrderItemJpaEntity> items = new ArrayList<>();

    @Column(name = "total_amount", nullable = false, precision = 19, scale = 2)
    private BigDecimal totalAmount;

    @Column(name = "total_currency", nullable = false, length = 3)
    private String totalCurrency;

    @Enumerated(EnumType.STRING) // R4 hardening: STRING (not ORDINAL) for backward compat
    @Column(name = "status", nullable = false, length = 32)
    private OrderStatus status;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    protected OrderJpaEntity() {}

    private OrderJpaEntity(UUID id, List<OrderItemJpaEntity> items,
                           BigDecimal totalAmount, String totalCurrency,
                           OrderStatus status, Instant createdAt, Long version) {
        this.id = id;
        this.items = items;
        this.totalAmount = totalAmount;
        this.totalCurrency = totalCurrency;
        this.status = status;
        this.createdAt = createdAt;
        this.version = version;
    }

    public static OrderJpaEntity fromDomain(Order order) {
        List<OrderItemJpaEntity> jpaItems = new ArrayList<>();
        for (OrderItem item : order.getItems()) {
            jpaItems.add(new OrderItemJpaEntity(
                item.getProductId(),
                item.getQuantity(),
                item.getPrice().amount(),
                item.getPrice().currency()
            ));
        }
        return new OrderJpaEntity(
            order.getId().value(),
            jpaItems,
            order.getTotal().amount(),
            order.getTotal().currency(),
            order.getStatus(),
            order.getCreatedAt(),
            order.getVersion()
        );
    }

    public Order toDomain() {
        List<OrderItem> domainItems = new ArrayList<>();
        for (OrderItemJpaEntity ji : items) {
            domainItems.add(new OrderItem(
                ji.getProductId(),
                ji.getQuantity(),
                new Money(ji.getPriceAmount(), ji.getPriceCurrency())
            ));
        }
        return Order.restore(
            new OrderId(id),
            domainItems,
            new Money(totalAmount, totalCurrency),
            status,
            createdAt,
            version
        );
    }

    public UUID getId() { return id; }
    public Long getVersion() { return version; }
}
