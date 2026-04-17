# FR-XX: <one-line imperative title>

> **Copy this file.** Rename to `FR-XX-<slug>.md`, remove the leading
> underscore, fill in every section. Add the row to `RTM.md` in the
> same PR.

---

## Metadata

- **FR ID**: FR-XX
- **Status**: Draft / Design / Implementing / Done / Deprecated
- **GitHub Issue**: #NNN
- **Related ADRs**: ADR-NNN (optional)
- **Owner**: @github-handle
- **Created**: YYYY-MM-DD

## User story

As a **<actor>**, I want **<capability>**, so that **<outcome>**.

## Trigger

Who or what starts this? HTTP request? `@Scheduled` job? Event on a
Spring Application Event bus? Kafka consumer?

## Inputs

| Name | Java type | Bean Validation | Source | Constraints |
|---|---|---|---|---|
| `exampleId` | `UUID` | `@NotNull` | `@PathVariable` | must exist in `users` table |
| `payload` | `ExampleRequestDto` (record) | `@Valid` | `@RequestBody` | see DTO field annotations |

## Outputs

| Name | Java type | Consumer | Notes |
|---|---|---|---|
| `ExampleResponseDto` (record) | `ApiResponse<ExampleResponseDto>` | `@RestController` → HTTP 200 body | wrapped by the project's response envelope |

## Preconditions

What must be true **before** this runs? These become guard clauses,
`@Transactional` boundary decisions, or Spring Security rules. Name
the code that enforces each.

- [ ] Caller is authenticated (`SecurityFilterChain` verifies JWT)
- [ ] `exampleId` exists in `users` (checked by `UserRepository.findById`)

## Postconditions

What must be true **after** this completes? These become assertions
in JUnit tests.

- [ ] Response body is `ApiResponse<ExampleResponseDto>` with `result="SUCCESS"`
- [ ] `analytics_events` row inserted with `event_type='example_accessed'`
- [ ] Operation is **idempotent** — repeat calls with same inputs do
  not create duplicate rows

## Structured logic

Describe the flow in **structured English** — constrained grammar
(`IF … THEN … ELSE`, `FOR EACH`, `WHILE`, `RETURN`). No natural-language
ambiguity. An LLM implementing from this spec should produce one
compilable `@Service` method.

```
BEGIN FR-XX (in ExampleService, @Transactional)
  VALIDATE input via Bean Validation (@Valid on controller)
  FETCH user FROM userRepository BY exampleId
  IF user IS EMPTY THEN
    THROW CoreException(ErrorType.USER_NOT_FOUND)
  END IF
  IF user.isBlocked THEN
    THROW CoreException(ErrorType.USER_BLOCKED)
  END IF
  INSERT into analyticsEvents (event_type, user_id, ts)
  RETURN ExampleResponseDto.from(user)
END FR-XX
```

The `ApiControllerAdvice` converts `CoreException` to
`ApiResponse(result=FAIL, error=...)` with the matching HTTP status.

## Decision table

**Only include this section if the logic has 3+ interacting conditions.**
One row per condition, one column per Rule. Y / N / — (don't care).

| Conditions                        | R1 | R2 | R3 | R4 |
|---|---|---|---|---|
| User exists                       | N  | Y  | Y  | Y  |
| User is blocked                   | —  | Y  | N  | N  |
| Premium feature requested         | —  | —  | Y  | N  |
| **Actions**                       |    |    |    |    |
| Throw `USER_NOT_FOUND` (404)      | X  |    |    |    |
| Throw `USER_BLOCKED` (403)        |    | X  |    |    |
| Throw `PREMIUM_REQUIRED` (403)    |    |    | X  |    |
| Return `ExampleResponseDto`       |    |    |    | X  |

**Test coverage rule**: one test per Rule column. 4 Rules = 4 tests
minimum. No Rule column may be untested.

## Exception handling

- **DB connection failure**: Spring's transaction manager rolls back
  automatically. Bubble to `ApiControllerAdvice` → 503 `SERVICE_UNAVAILABLE`
- **Validation failure**: `@Valid` throws `MethodArgumentNotValidException`
  — `ApiControllerAdvice` converts to `ApiResponse(result=FAIL, error=VALIDATION_ERROR)`
- **Optimistic locking conflict**: `@Version` on the entity causes
  `OptimisticLockException` on concurrent edit — map to 409 `CONCURRENT_MODIFICATION`
- **External API timeout**: wrap calls with a circuit breaker (Resilience4j) or timeout; on failure, throw `CoreException(ErrorType.UPSTREAM_UNAVAILABLE)`

## Test plan

| Level | Scenario | File |
|---|---|---|
| unit (Mockito) | service happy path | `src/test/java/.../ExampleServiceTest.java` |
| unit | each decision-table Rule (R1 … RN) | `src/test/java/.../ExampleServiceRulesTest.java` |
| integration (`@WebMvcTest`) | controller with mocked service | `src/test/java/.../ExampleControllerWebMvcTest.java` |
| integration (Testcontainers) | DB schema + repository | `src/test/java/.../ExampleRepositoryIT.java` |
| ArchUnit | layer boundary (auto) | `src/test/java/.../architecture/ArchitectureTest.java` |

## Open questions

<!-- Resolved questions become part of the spec above. -->

- [ ] ...
