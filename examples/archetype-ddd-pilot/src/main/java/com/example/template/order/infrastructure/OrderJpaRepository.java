package com.example.template.order.infrastructure;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

interface OrderJpaRepository extends JpaRepository<OrderJpaEntity, UUID> {
}
