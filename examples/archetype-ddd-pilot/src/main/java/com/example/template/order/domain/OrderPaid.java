package com.example.template.order.domain;

import org.jmolecules.event.annotation.DomainEvent;

@DomainEvent
public record OrderPaid(OrderId orderId, Money total) {}
