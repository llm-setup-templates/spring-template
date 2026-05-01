package com.example.template.order.application;

import java.util.Objects;

public record PayOrderCommand(String paymentRef) {

    public PayOrderCommand {
        Objects.requireNonNull(paymentRef, "paymentRef must not be null");
    }
}
