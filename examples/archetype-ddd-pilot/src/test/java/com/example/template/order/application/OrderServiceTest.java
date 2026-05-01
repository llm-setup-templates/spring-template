package com.example.template.order.application;

import com.example.template.order.domain.Money;
import com.example.template.order.domain.Order;
import com.example.template.order.domain.OrderCancelled;
import com.example.template.order.domain.OrderCreated;
import com.example.template.order.domain.OrderItem;
import com.example.template.order.domain.OrderRepository;
import com.example.template.support.error.CoreException;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.event.RecordApplicationEvents;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.math.BigDecimal;
import java.time.Duration;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@SpringBootTest
@Testcontainers
@RecordApplicationEvents
@Import(OrderServiceTest.TestConfig.class)
class OrderServiceTest {

    @TestConfiguration
    static class TestConfig {
        @Bean
        OrderCreatedListener orderCreatedListener() {
            return new OrderCreatedListener();
        }
    }


    @Container
    @ServiceConnection
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16")
        .withStartupTimeout(Duration.ofMinutes(2));

    @Autowired OrderService orderService;
    @Autowired OrderRepository repository;
    @Autowired OrderCreatedListener listener;

    private static OrderItem item(String price, int qty) {
        return new OrderItem(UUID.randomUUID(), qty, new Money(new BigDecimal(price), "KRW"));
    }

    @Test
    void createOrder_persists() {
        Order order = orderService.createOrder(new CreateOrderCommand(List.of(item("1000", 2))));
        assertThat(order.getId()).isNotNull();
        assertThat(order.getVersion()).isNotNull();
        assertThat(repository.findById(order.getId())).isPresent();
    }

    @Test
    void createOrder_publishesEventAfterCommit() {
        listener.reset();
        orderService.createOrder(new CreateOrderCommand(List.of(item("1000", 1))));
        assertThat(listener.getCount()).isEqualTo(1);
    }

    @Test
    void getOrder_notFound_throwsCoreException() {
        assertThatThrownBy(() ->
            orderService.getOrder(new com.example.template.order.domain.OrderId(UUID.randomUUID())))
            .isInstanceOf(CoreException.class);
    }

    @Test
    void cancelOrder_updatesStatus() {
        Order created = orderService.createOrder(new CreateOrderCommand(List.of(item("1000", 1))));
        Order cancelled = orderService.cancelOrder(created.getId());
        assertThat(cancelled.getStatus())
            .isEqualTo(com.example.template.order.domain.OrderStatus.CANCELLED);
    }

    /**
     * AFTER_COMMIT TX-bound listener: counts events that survived commit.
     * R2 CX-10: rollback path leaves count at 0.
     * Registered via TestConfig.@Bean above (no @Component because Spring
     * cannot component-scan test class inner classes reliably).
     */
    static class OrderCreatedListener {
        private final AtomicInteger count = new AtomicInteger();

        @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
        void on(OrderCreated event) {
            count.incrementAndGet();
        }

        void reset() { count.set(0); }
        int getCount() { return count.get(); }
    }
}
