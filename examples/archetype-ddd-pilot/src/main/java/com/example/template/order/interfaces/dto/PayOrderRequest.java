package com.example.template.order.interfaces.dto;

import com.example.template.order.application.PayOrderCommand;

import jakarta.validation.constraints.NotBlank;

public record PayOrderRequest(@NotBlank String paymentRef) {

    public PayOrderCommand toCommand() {
        return new PayOrderCommand(paymentRef);
    }
}
