package com.example.template.order.interfaces.dto;

import com.example.template.order.application.CreateOrderCommand;
import com.example.template.order.domain.Money;
import com.example.template.order.domain.OrderItem;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

public record CreateOrderRequest(
    @NotEmpty(message = "items must not be empty")
    @Valid
    List<ItemDto> items
) {
    public record ItemDto(
        @NotNull UUID productId,
        @Positive int quantity,
        @NotNull BigDecimal priceAmount,
        @NotNull String priceCurrency
    ) {
        public OrderItem toDomain() {
            return new OrderItem(productId, quantity, new Money(priceAmount, priceCurrency));
        }
    }

    public CreateOrderCommand toCommand() {
        return new CreateOrderCommand(items.stream().map(ItemDto::toDomain).toList());
    }
}
