# archetype-ddd-pilot — DDD/TDD worked example

> Standalone Gradle project. Worked example for Phase E DDD/TDD stack (jMolecules + Spring Modulith + Testcontainers + Classicist TDD).
>
> **scaffold.sh removes `examples/` (Stage F).** This directory is a **learning artifact**, not part of the scaffolded output.

## Purpose

Spring Boot 3.5 + Java 17 reference implementation demonstrating:
- DDD tactical patterns (jMolecules `@AggregateRoot` / `@DomainEvent` / `@ValueObject` / `@Repository`)
- Spring Modulith module boundary (`ApplicationModules.verify()`)
- ArchUnit DDD rules (R13-R16: aggregate / event / repository / dependency inversion)
- Classicist TDD (Testcontainers Postgres, no domain mocking)
- Self-managed domain event buffer (no `AbstractAggregateRoot` dependency)

## Domain — Order aggregate (Eric Evans)

- `Order` (aggregate root) + `OrderItem` (entity)
- `OrderStatus` value object (5 states + transition matrix)
- `Money` value object
- 3 domain events: `OrderCreated`, `OrderCancelled`, `OrderPaid`

## Layout

```
src/main/java/com/example/template/
├── TemplateApplication.java
└── order/
    ├── domain/          # @AggregateRoot / @DomainEvent / @ValueObject (jMolecules)
    ├── application/     # @Service use cases + Commands
    ├── infrastructure/  # JPA mapping + Repository impl
    └── interfaces/      # @RestController + DTOs
```

## Run

```bash
# Prerequisites: JDK 17+, Docker Desktop running (for Testcontainers Postgres)
cd examples/archetype-ddd-pilot
./gradlew test build
```

## E0 gate

This archetype is the pilot for Phase E (DDD/TDD across spring/python/typescript). Pass criteria:
1. V_drift PASS (cross-template byte-identical)
2. `ApplicationModules.verify()` PASS (Spring Modulith module boundary 0 violation)
3. ArchUnit 4 DDD rules PASS (DddArchitectureTest)
4. Order Testcontainers integration tests >= 4 PASS
5. phase-e-pr-template.md SHA256 inheritance verified (`scripts/check-e0-gate.sh`)

## References

- DISCUSS Q1-Q12 LOCK: `.plans/E-ddd-tdd-3-template-stack/DISCUSS.md`
- PLAN rev.5: `.plans/E-ddd-tdd-3-template-stack/PLAN.md`
- 14a-bis Phase E entry gate: `SETUP.md` `### Phase E (DDD/TDD) stack hook`
- Pattern doc (3 stacks): `docs/patterns/ddd-tdd-cross-stack.md`
