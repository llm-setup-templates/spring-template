package com.example.template.order.domain;

public class InvalidStatusTransitionException extends RuntimeException {

    private final OrderStatus from;
    private final OrderStatus to;

    public InvalidStatusTransitionException(OrderStatus from, OrderStatus to) {
        super("Cannot transition from " + from + " to " + to);
        this.from = from;
        this.to = to;
    }

    public OrderStatus getFrom() { return from; }
    public OrderStatus getTo() { return to; }
}
