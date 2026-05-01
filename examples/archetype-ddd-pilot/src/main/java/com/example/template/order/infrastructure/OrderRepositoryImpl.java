package com.example.template.order.infrastructure;

import com.example.template.order.domain.Order;
import com.example.template.order.domain.OrderId;
import com.example.template.order.domain.OrderRepository;

import org.springframework.context.ApplicationEventPublisher;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

// R4 CX-27: @Transactional explicit -- TX context required for saveAndFlush + publishEvent.
@org.springframework.stereotype.Repository
@Transactional
public class OrderRepositoryImpl implements OrderRepository {

    private final OrderJpaRepository jpa;
    private final ApplicationEventPublisher eventPublisher;

    public OrderRepositoryImpl(OrderJpaRepository jpa, ApplicationEventPublisher eventPublisher) {
        this.jpa = jpa;
        this.eventPublisher = eventPublisher;
    }

    @Override
    public Order save(Order order) {
        OrderJpaEntity entity = OrderJpaEntity.fromDomain(order);
        // R2 CX-11: saveAndFlush -- optimistic lock conflict surfaces immediately at flush.
        OrderJpaEntity saved = jpa.saveAndFlush(entity);
        Order persisted = saved.toDomain();
        // R2 C-2 / CX-9: snapshot + try/finally -- guarantees clearDomainEvents even if listener throws.
        List<Object> events = List.copyOf(order.domainEvents());
        try {
            events.forEach(eventPublisher::publishEvent);
        } finally {
            order.clearDomainEvents();
        }
        return persisted;
    }

    @Override
    @Transactional(readOnly = true)
    public Optional<Order> findById(OrderId id) {
        return jpa.findById(id.value()).map(OrderJpaEntity::toDomain);
    }
}
