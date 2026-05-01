package com.example.template.order.domain;

import org.jmolecules.ddd.annotation.ValueObject;

import java.util.Objects;
import java.util.UUID;

@ValueObject
public record OrderId(UUID value) {

    public OrderId {
        Objects.requireNonNull(value, "OrderId value must not be null");
    }

    public static OrderId generate() {
        return new OrderId(UUID.randomUUID());
    }
}
