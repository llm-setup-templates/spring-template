package com.example.template.order.domain;

public class InvariantViolationException extends RuntimeException {

    public InvariantViolationException(String message) {
        super(message);
    }
}
