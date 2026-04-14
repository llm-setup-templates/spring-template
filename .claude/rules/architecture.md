# Architecture Rules — Java / Spring Boot

> Concrete module boundary and export conventions for Spring Boot 3 + Java 21.

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
├── controller/        HTTP layer (@RestController)
├── service/           Business logic (@Service, @Transactional)
├── repository/        Data access (JpaRepository interfaces)
├── domain/            JPA entities (@Entity) — no exposure to HTTP
├── dto/               Request/Response objects — NO JPA annotations
└── config/            Spring configuration (@Configuration)
```

### Layer Dependency Direction (ArchUnit enforced)
Controller → Service → Repository  (unidirectional only)

### Module Export (Public API) Rules
- `domain/` classes: accessible only from `service/` and `repository/`
- `dto/` classes: accessible from `controller/` and `service/`
- `config/` classes: accessible from any layer
- No cross-layer direct access (Controller must not call Repository directly)

### Multi-Module Scaling Path
When scaling to multi-module (team-dodn pattern), package names map to modules:
- `com.example.core` → `core/` module
- `com.example.clients` → `clients/` module
- `com.example.storage` → `storage/` module
- `com.example.support` → `support/` module

ArchUnit rule 6 (T8) enforces this package boundary from day one.

### Circular Dependency Policy
Zero tolerance. ArchUnit `slices().matching("..(*)..")` rule will be added
when package count exceeds 5.

## Universal Principles
- Dependency direction: outer layers may depend on inner layers, never reverse
- Public API minimization: expose the smallest surface that callers need
- No "util dump" packages — every file has a single responsibility
