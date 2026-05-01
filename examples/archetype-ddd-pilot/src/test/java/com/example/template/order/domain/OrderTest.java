package com.example.template.order.domain;

import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class OrderTest {

    private static OrderItem item(String price, int qty) {
        return new OrderItem(UUID.randomUUID(), qty, new Money(new BigDecimal(price), "KRW"));
    }

    @Test
    void create_happy_calculatesTotalAndRegistersEvent() {
        OrderItem a = item("1000", 2); // 2000
        OrderItem b = item("500", 3);  // 1500
        Order order = Order.create(List.of(a, b));

        assertThat(order.getStatus()).isEqualTo(OrderStatus.CREATED);
        assertThat(order.getTotal()).isEqualTo(new Money(new BigDecimal("3500"), "KRW"));
        assertThat(order.getItems()).hasSize(2);
        assertThat(order.getCreatedAt()).isNotNull();
        assertThat(order.domainEvents()).hasSize(1);
        assertThat(order.domainEvents().get(0)).isInstanceOf(OrderCreated.class);
        OrderCreated evt = (OrderCreated) order.domainEvents().get(0);
        assertThat(evt.itemCount()).isEqualTo(2);
        assertThat(evt.total()).isEqualTo(order.getTotal());
    }

    @Test
    void create_emptyItems_throws() {
        assertThatThrownBy(() -> Order.create(List.of()))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessageContaining("at least one item");
    }

    @Test
    void create_nullItems_throws() {
        assertThatThrownBy(() -> Order.create(null))
            .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void cancel_fromCreated_succeeds() {
        Order order = Order.create(List.of(item("1000", 1)));
        order.clearDomainEvents();
        order.cancel();

        assertThat(order.getStatus()).isEqualTo(OrderStatus.CANCELLED);
        assertThat(order.domainEvents()).hasSize(1);
        assertThat(order.domainEvents().get(0)).isInstanceOf(OrderCancelled.class);
    }

    @Test
    void cancel_fromPaid_succeeds() {
        Order order = Order.create(List.of(item("1000", 1)));
        order.pay();
        order.clearDomainEvents();
        order.cancel();

        assertThat(order.getStatus()).isEqualTo(OrderStatus.CANCELLED);
    }

    @Test
    void cancel_fromCancelled_throws() {
        Order order = Order.create(List.of(item("1000", 1)));
        order.cancel();
        assertThatThrownBy(order::cancel)
            .isInstanceOf(InvalidStatusTransitionException.class);
    }

    @Test
    void cancel_fromDelivered_throws() {
        Order delivered = Order.restore(
            OrderId.generate(),
            List.of(item("1000", 1)),
            new Money(new BigDecimal("1000"), "KRW"),
            OrderStatus.DELIVERED,
            java.time.Instant.now(),
            0L
        );
        assertThatThrownBy(delivered::cancel)
            .isInstanceOf(InvalidStatusTransitionException.class);
    }

    @Test
    void pay_fromCreated_succeeds() {
        Order order = Order.create(List.of(item("1000", 1)));
        order.clearDomainEvents();
        order.pay();

        assertThat(order.getStatus()).isEqualTo(OrderStatus.PAID);
        assertThat(order.domainEvents()).hasSize(1);
        assertThat(order.domainEvents().get(0)).isInstanceOf(OrderPaid.class);
    }

    @Test
    void pay_fromPaid_throws() {
        Order order = Order.create(List.of(item("1000", 1)));
        order.pay();
        assertThatThrownBy(order::pay)
            .isInstanceOf(InvalidStatusTransitionException.class);
    }

    @Test
    void orderStatus_canTransitionTo_matrix() {
        // CREATED -> PAID, CANCELLED only
        assertThat(OrderStatus.CREATED.canTransitionTo(OrderStatus.PAID)).isTrue();
        assertThat(OrderStatus.CREATED.canTransitionTo(OrderStatus.CANCELLED)).isTrue();
        assertThat(OrderStatus.CREATED.canTransitionTo(OrderStatus.SHIPPED)).isFalse();

        // PAID -> SHIPPED, CANCELLED
        assertThat(OrderStatus.PAID.canTransitionTo(OrderStatus.SHIPPED)).isTrue();
        assertThat(OrderStatus.PAID.canTransitionTo(OrderStatus.CANCELLED)).isTrue();
        assertThat(OrderStatus.PAID.canTransitionTo(OrderStatus.DELIVERED)).isFalse();

        // SHIPPED -> DELIVERED only
        assertThat(OrderStatus.SHIPPED.canTransitionTo(OrderStatus.DELIVERED)).isTrue();
        assertThat(OrderStatus.SHIPPED.canTransitionTo(OrderStatus.CANCELLED)).isFalse();

        // DELIVERED, CANCELLED -> none
        for (OrderStatus s : OrderStatus.values()) {
            assertThat(OrderStatus.DELIVERED.canTransitionTo(s)).isFalse();
            assertThat(OrderStatus.CANCELLED.canTransitionTo(s)).isFalse();
        }
    }

    @Test
    void clearDomainEvents_emptiesBuffer() {
        Order order = Order.create(List.of(item("1000", 1)));
        assertThat(order.domainEvents()).hasSize(1);
        order.clearDomainEvents();
        assertThat(order.domainEvents()).isEmpty();
    }
}
