# DDD/TDD Cross-Stack Pattern Doc (Phase E0 Pilot)

> Status: **E0 Pilot — Spring row only.** Python/TypeScript rows added in Phase E (post-E0 gate).
>
> Q6=A LOCK: pattern doc only. **No code/interface sharing across stacks.** Each stack expresses DDD/TDD in its native idiom.
>
> Q1=D + 14a-bis Q4=A LOCK: convention precedence > shared abstraction.

## Context

Phase E introduces DDD (Domain-Driven Design) tactical patterns + TDD (Test-Driven Development) discipline to 3 templates (spring/python/typescript). This pattern doc captures **how each stack expresses the same DDD/TDD concept**, without imposing byte-identical implementations.

**Source**: DDD/TDD research distillation (Obsidian 7 notes — N1-N6 + P2). Bibliography: 25 entries (Evans / Vernon / Beck / Bogard / Khorikov / Cockburn / Fowler / Bazel Test Encyclopedia).

## 3-Axis Pattern Matrix

| Concept | Spring (E0 Pilot) | Python (Phase E) | TypeScript (Phase E) |
|---|---|---|---|
| **Aggregate Root expression** | `@org.jmolecules.ddd.annotation.AggregateRoot` (jmolecules-ddd 1.9.0) on plain class. Self-managed `domainEvents` buffer (no `AbstractAggregateRoot` to keep domain layer free of `spring-data-commons`). | _TBD (post-E0 — pydantic dataclass + `@aggregate_root` decorator)_ | _TBD (post-E0 — class with brand type tag, e.g. `__brand: "AggregateRoot"`)_ |
| **Domain Event expression** | `@org.jmolecules.event.annotation.DomainEvent` (jmolecules-events 1.9.0) on Java record. Drained via `OrderRepositoryImpl.save()` -> `ApplicationEventPublisher.publishEvent(Object)`. Consumers use `@TransactionalEventListener(phase = AFTER_COMMIT)` (rollback-safe). | _TBD (post-E0 — pydantic event model + `dispatch_event()` callable)_ | _TBD (post-E0 — discriminated union event types + event bus)_ |
| **Value Object expression** | `@org.jmolecules.ddd.annotation.ValueObject` on Java record (or enum). Compact constructor for invariant. | _TBD (post-E0 — pydantic model with `model_config = ConfigDict(frozen=True)`)_ | _TBD (post-E0 — `Readonly<{...}>` types + zod schema)_ |
| **Repository interface vs impl** | jMolecules `@Repository` interface in `..domain..` package. Spring `@Repository` impl class in `..infrastructure..`. ArchUnit R15 enforces. | _TBD (post-E0 — Protocol in domain, concrete class in infra)_ | _TBD (post-E0 — interface in domain layer, drizzle-backed impl in infra)_ |
| **Module boundary verification** | Spring Modulith 1.4.0 `ApplicationModules.of(TemplateApplication.class).verify()` -- 1 test asserts 0 violations. Module = top-level subpackage (e.g., `order`). | _TBD (post-E0 — import-linter contracts or layered tests)_ | _TBD (post-E0 — eslint-plugin-boundaries or ts-arch)_ |
| **Architecture rules (DDD)** | ArchUnit 4 rules (R13-R16): @AggregateRoot in domain / @DomainEvent in domain / Repository interface in domain / domain not depend on infrastructure | _TBD (post-E0 — pylint custom checker or import-linter rules)_ | _TBD (post-E0 — eslint custom rules or ts-arch tests)_ |
| **TDD discipline** | Classicist (Detroit/Chicago school) -- domain unit tests use real POJOs, no mocks. Integration tests use Testcontainers Postgres + real Hibernate (D2 LOCK). | _TBD (post-E0 — pytest + Testcontainers + real SQLAlchemy)_ | _TBD (post-E0 — vitest + Testcontainers + real drizzle)_ |
| **Aggregate invariant test** | Pure POJO test (`OrderTest`) -- `Order.create(items)` factory enforces `total = sum(price * quantity)`. Direct exception assertion via AssertJ. | _TBD (post-E0 — pytest fixture + assertRaises)_ | _TBD (post-E0 — vitest expect().toThrow())_ |
| **Worked example domain** | Order / OrderItem aggregate (Eric Evans canonical, Q4=A LOCK). Status enum (CREATED/PAID/SHIPPED/DELIVERED/CANCELLED) + transition matrix. | Same domain (Order aggregate) -- different stack idiom | Same domain (Order aggregate) -- different stack idiom |

## Why no shared abstraction

14a-bis Q4=A LOCK: **"convention precedence > shared abstraction"**.

If 3 stacks could share byte-identical contract test interfaces, the 3-template separation would lose justification (Phase 14a would collapse). Therefore:
- Pattern doc captures shared **concepts** (this file)
- Each stack writes its own concrete implementation
- Cross-stack verification = manual reading of contract test names + scenarios, NOT automated parity check

## References

- Codex thread (DDD/TDD research, separation strategy): `019ddee8-01f0-7f22-a5eb-ab448e021aae`
- Obsidian: `Sources/sw-engineering/2026-04-30-ddd-tdd-synergy-thesis.md` (N2 thesis delta)
- Obsidian: `Sources/sw-engineering/2026-04-30-no-mocking-aggregate-debate.md` (N5 Classicist)
- Obsidian: `Sources/sw-engineering/cases/2026-04-30-spring-modulith-modular-monolith.md` (N3)
- 14a-bis Phase E entry rubric: `.agents/rules/plan-review-deep.md` § 5
- Phase E hook 5-line meaning checklist: `SETUP.md` `### Phase E (DDD/TDD) stack hook`

## Domain layer no-mocking

Domain layer tests (entities, value objects, aggregates) verify behavior
through the aggregate's public API. Mocks are forbidden in this layer.

- **Why**: domain logic must be deterministic + framework-independent.
  Mocking implementation details couples tests to internal structure.
- **How**: construct real aggregates via factories; assert on returned
  domain events / state transitions / domain exceptions.
- **Reference**: `.claude/skills/tdd/mocking.md` (Pocock vendor) +
  `.claude/skills/office-hours-ddd-discovery/SKILL.md` Q4 (Aggregate
  root boundary).
- **Cross-stack**: typescript `examples/archetype-ddd-pilot/seed/__tests__/domain/Order.test.ts`
  applies the same pattern.
