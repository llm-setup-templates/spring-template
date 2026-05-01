package com.example.template.order.application;

import com.example.template.order.domain.Order;
import com.example.template.order.domain.OrderId;
import com.example.template.order.domain.OrderRepository;
import com.example.template.support.error.CoreException;
import com.example.template.support.error.ErrorType;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional
public class OrderService {

    private final OrderRepository repository;

    public OrderService(OrderRepository repository) {
        this.repository = repository;
    }

    public Order createOrder(CreateOrderCommand cmd) {
        Order order = Order.create(cmd.items());
        return repository.save(order);
    }

    @Transactional(readOnly = true)
    public Order getOrder(OrderId id) {
        return repository.findById(id)
            .orElseThrow(() -> new CoreException(ErrorType.NOT_FOUND, "Order not found: " + id.value()));
    }

    public Order cancelOrder(OrderId id) {
        Order order = getOrder(id);
        order.cancel(); // throws InvalidStatusTransitionException on bad transition
        return repository.save(order);
    }

    public Order payOrder(OrderId id, PayOrderCommand cmd) {
        Order order = getOrder(id);
        order.pay(); // throws InvalidStatusTransitionException on bad transition
        return repository.save(order);
    }
}
