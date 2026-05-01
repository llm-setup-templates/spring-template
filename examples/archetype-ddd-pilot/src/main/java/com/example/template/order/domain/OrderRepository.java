package com.example.template.order.domain;

import org.jmolecules.ddd.annotation.Repository;

import java.util.Optional;

@Repository
public interface OrderRepository {

    Order save(Order order);

    Optional<Order> findById(OrderId id);
}
