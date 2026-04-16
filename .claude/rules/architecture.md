# Architecture Rules — Java / Spring Boot

> Concrete module boundary and export conventions for Spring Boot 3 + Java 17.

## Required Content per Language Template

Each derived `architecture.md` MUST specify:
1. **Directory layout** — top-level folders and their responsibilities
2. **Module boundaries** — what can import what (import direction)
3. **Public API surface** — how modules expose symbols
4. **Circular dependency policy** — absolute prohibition
5. **Cross-layer access rules** — which layers may talk to which

## Java / Spring Boot — Package & Layer Rules

### Package Structure
```
src/main/java/com/example/{projectname}/
├── core/
│   ├── api/
│   │   ├── controller/     # HTTP layer (@RestController) — versioned: v1/
│   │   ├── config/         # Spring @Configuration for API concerns
│   │   └── support/        # ControllerAdvice, interceptors
│   ├── domain/             # Business logic (@Service) + domain objects
│   │   └── {feature}/      # Feature-scoped services and domain objects
│   └── enums/              # Shared enums (cross-module safe)
├── storage/
│   └── db/
│       ├── entity/         # JPA @Entity — NEVER returned from controllers
│       ├── repository/     # JpaRepository interfaces
│       └── config/         # DataSource, JPA config
├── clients/
│   └── {external}/         # External API clients (OpenFeign, RestClient)
│       ├── dto/            # Client-specific request/response DTOs
│       └── config/         # Client configuration
└── support/
    ├── error/              # CoreException, ErrorCode, ErrorType
    ├── response/           # ApiResponse<T>, ResultType
    └── logging/            # Logback config, structured logging
```

### Layer Dependency Direction (ArchUnit enforced)
Controller → Service → Repository  (existing, maintained)
core.api → core.domain → (interface only) ← storage.db  (DIP)
core.* → support.*  (allowed)
storage.* ←✗→ clients.*  (mutual prohibition)
core.domain →✗ storage.*  (no direct import, use interfaces)

### Module Export (Public API) Rules
- `domain/` classes: accessible only from `service/` and `repository/`
- `dto/` classes: accessible from `controller/` and `service/`
- `config/` classes: accessible from any layer
- No cross-layer direct access (Controller must not call Repository directly)

## [CRITICAL] AI Agent Architectural Constraints — Spring Boot

### 1. Global Response Envelope
- NEVER return raw entities or `Map<String,Object>` from @RestController methods.
- ALWAYS wrap in `ApiResponse<T>` (see `examples/support/response/ApiResponse.java`).
- NEVER throw Spring's `ResponseStatusException` in service/domain layers.
  Use `CoreException(ErrorType.xxx)` only. `ApiControllerAdvice` converts it to `ApiResponse`.

### 2. Layer Dependency Isolation (ArchUnit enforced)
- `core.domain` MUST NOT import `storage.*`, `clients.*`, or `jakarta.persistence.*`.
- `storage` MUST NOT import `clients`. `clients` MUST NOT import `storage`.
- `support` has zero business logic — importable by all layers.

### 3. Observability Isolation
- `System.out.println()` and `System.err.println()` are prohibited.
- Use SLF4J `Logger` obtained via `LoggerFactory.getLogger(getClass())`.

### 4. Required Execution Sequence
1. IDENTIFY: controller? service? repository? support?
2. SEARCH: `grep -r "similar pattern" src/main/java/`
3. VERIFY: check ArchUnit rules in `ArchitectureTest.java`
4. PUBLIC API: import via package, not inner class

### 5. Multi-Module Readiness
Current structure is single-module but package-named for team-dodn migration:

| Package | Future Module | Gradle path |
|---------|---------------|-------------|
| `core.api` | `core:core-api` | `core/core-api` |
| `core.domain` | `core:core-api` (domain) | `core/core-api` |
| `core.enums` | `core:core-enum` | `core/core-enum` |
| `storage.db` | `storage:db-core` | `storage/db-core` |
| `clients.*` | `clients:client-*` | `clients/client-*` |
| `support.*` | `support:logging`, `support:monitoring` | `support/*` |

When ready to split, extract packages into Gradle submodules. ArchUnit rules carry over.

### Multi-Module Scaling Path
See §5 above for the full package-to-module mapping table.

### Circular Dependency Policy
Zero tolerance. ArchUnit `slices().matching("..(*)..")` rule will be added
when package count exceeds 5.

## Universal Principles
- Dependency direction: outer layers may depend on inner layers, never reverse
- Public API minimization: expose the smallest surface that callers need
- No "util dump" packages — every file has a single responsibility
