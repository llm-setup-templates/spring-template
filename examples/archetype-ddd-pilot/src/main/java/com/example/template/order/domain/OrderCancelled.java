package com.example.template.order.domain;

import org.jmolecules.event.annotation.DomainEvent;

@DomainEvent
public record OrderCancelled(OrderId orderId) {}
