package com.example.template.order.domain;

import org.jmolecules.ddd.annotation.AggregateRoot;
import org.jmolecules.ddd.annotation.Identity;

import java.time.Instant;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Objects;

@AggregateRoot
public class Order {

    @Identity
    private final OrderId id;
    private final List<OrderItem> items;
    private final Money total;
    private OrderStatus status;
    private final Instant createdAt;
    private Long version; // optimistic lock token, populated on restoration from JPA

    // Self-managed domain event buffer (no AbstractAggregateRoot dependency).
    // Drained by OrderRepositoryImpl after persistence (see PLAN D4).
    private final transient List<Object> domainEvents = new ArrayList<>();

    private Order(OrderId id, List<OrderItem> items, Money total,
                  OrderStatus status, Instant createdAt, Long version) {
        this.id = id;
        this.items = List.copyOf(items);
        this.total = total;
        this.status = status;
        this.createdAt = createdAt;
        this.version = version;
    }

    public static Order create(List<OrderItem> items) {
        if (items == null || items.isEmpty()) {
            throw new IllegalArgumentException("Order must have at least one item");
        }
        Money calculated = items.stream()
            .map(OrderItem::lineTotal)
            .reduce(Money.zero(items.get(0).getPrice().currency()), Money::add);
        Order o = new Order(OrderId.generate(), items, calculated,
            OrderStatus.CREATED, Instant.now(), null);
        o.registerEvent(new OrderCreated(o.id, calculated, o.items.size()));
        return o;
    }

    /**
     * Restoration constructor for infrastructure layer. Skips invariant re-validation
     * (the persisted aggregate already passed invariant at creation time).
     */
    public static Order restore(OrderId id, List<OrderItem> items, Money total,
                                OrderStatus status, Instant createdAt, Long version) {
        return new Order(Objects.requireNonNull(id), Objects.requireNonNull(items),
            Objects.requireNonNull(total), Objects.requireNonNull(status),
            Objects.requireNonNull(createdAt), version);
    }

    public void cancel() {
        if (!status.canTransitionTo(OrderStatus.CANCELLED)) {
            throw new InvalidStatusTransitionException(status, OrderStatus.CANCELLED);
        }
        this.status = OrderStatus.CANCELLED;
        registerEvent(new OrderCancelled(id));
    }

    public void pay() {
        if (!status.canTransitionTo(OrderStatus.PAID)) {
            throw new InvalidStatusTransitionException(status, OrderStatus.PAID);
        }
        this.status = OrderStatus.PAID;
        registerEvent(new OrderPaid(id, total));
    }

    private void registerEvent(Object event) {
        domainEvents.add(event);
    }

    public List<Object> domainEvents() {
        return Collections.unmodifiableList(domainEvents);
    }

    public void clearDomainEvents() {
        domainEvents.clear();
    }

    public OrderId getId() { return id; }
    public List<OrderItem> getItems() { return items; }
    public Money getTotal() { return total; }
    public OrderStatus getStatus() { return status; }
    public Instant getCreatedAt() { return createdAt; }
    public Long getVersion() { return version; }
}
