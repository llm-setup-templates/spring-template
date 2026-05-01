package com.example.template.order.interfaces;

import com.example.template.order.application.OrderService;
import com.example.template.order.domain.Order;
import com.example.template.order.domain.OrderId;
import com.example.template.order.interfaces.dto.CreateOrderRequest;
import com.example.template.order.interfaces.dto.OrderResponse;
import com.example.template.order.interfaces.dto.PayOrderRequest;
import com.example.template.support.response.ApiResponse;

import jakarta.validation.Valid;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/orders")
public class OrderController {

    private final OrderService service;

    public OrderController(OrderService service) {
        this.service = service;
    }

    @PostMapping
    public ResponseEntity<ApiResponse<OrderResponse>> create(@Valid @RequestBody CreateOrderRequest req) {
        Order order = service.createOrder(req.toCommand());
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(ApiResponse.success(OrderResponse.from(order)));
    }

    @GetMapping("/{id}")
    public ApiResponse<OrderResponse> get(@PathVariable UUID id) {
        return ApiResponse.success(OrderResponse.from(service.getOrder(new OrderId(id))));
    }

    @PostMapping("/{id}/cancel")
    public ApiResponse<OrderResponse> cancel(@PathVariable UUID id) {
        return ApiResponse.success(OrderResponse.from(service.cancelOrder(new OrderId(id))));
    }

    @PostMapping("/{id}/pay")
    public ApiResponse<OrderResponse> pay(@PathVariable UUID id, @Valid @RequestBody PayOrderRequest req) {
        return ApiResponse.success(OrderResponse.from(service.payOrder(new OrderId(id), req.toCommand())));
    }
}
