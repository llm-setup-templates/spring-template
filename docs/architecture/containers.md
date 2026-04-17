# Container diagram — C4 Level 2

> **Specification perspective.** This is one level deeper than
> `overview.md`. Here we name the runnable containers (API, worker,
> database, cache) and the responsibilities each takes. Frameworks
> and concrete technologies ARE named at this level.
>
> Still not at Code level — `containers.md` doesn't show classes.
> That's Level 3 (components) — deferred to the code itself unless a
> system is exceptionally complex.

## Diagram

```mermaid
%% C4 Level 2 — Containers
%% Edit: each box is a separately-deployable unit. Label with its
%% runtime technology and its single responsibility in one line.

flowchart TB
    User([User / Client])

    subgraph System["YOUR_SYSTEM"]
        API["Spring Boot API<br/>(Java 17 / Tomcat)<br/>REST endpoints,<br/>request validation,<br/>business logic"]
        Worker["Scheduled Worker<br/>(@Scheduled / Quartz)<br/>async / batch tasks"]
        DB[("Postgres<br/>(JPA / Hibernate)<br/>persistent state")]
        Cache[("Redis<br/>(Spring Cache)<br/>hot data / sessions")]
    end

    External[(External API<br/>OAuth / payment / fact-check / ...)]

    User -- HTTPS JSON --> API
    API -- JDBC --> DB
    API -- RESP --> Cache
    API -- HTTPS --> External
    Worker -- JDBC --> DB
    Worker -- HTTPS --> External

    classDef container fill:#438DD5,stroke:#2E6295,color:#fff
    classDef database fill:#438DD5,stroke:#2E6295,color:#fff
    classDef person fill:#08427B,stroke:#052E56,color:#fff
    classDef external fill:#999,stroke:#666,color:#fff
    class API,Worker container
    class DB,Cache database
    class User person
    class External external
```

## Containers

One row per box in the diagram.

| Container | Technology | Responsibility |
|---|---|---|
| API | Spring Boot 3 / Java 17, Tomcat | REST endpoints, DTO validation, orchestrate services, call DB + external APIs |
| Scheduled Worker | Spring `@Scheduled` or Quartz | Cron jobs, batch enrichment, async cleanup |
| Database | Postgres 16 (JPA / Hibernate) | Persistent state, transactional integrity |
| Cache | Redis (Spring Cache / Redisson) | Session cache, rate-limit counters, hot keys |

Delete any row that isn't used. For example, many MVPs have no
Worker and no Cache — `API + Database` is a legitimate two-container
system.

## Boundary rules (enforced by ArchUnit)

Each container maps to the package layers it's allowed to exercise:

- **API** (`core.api.controller.*`): HTTP layer only. Must not call
  `storage.*` directly — goes through `core.domain.*`
- **Worker** (`core.api.scheduler.*`): same constraints as API, but
  triggered by cron
- **`core.domain`**: business logic; talks to `storage.*`
  **only through repository interfaces** (DIP)
- **`storage.db`**: JPA entities + repositories — never imported by
  controllers (enforced by ArchUnit `layeredArchitecture` rule)
- **`clients.*`**: external API clients; cannot import `storage.*` or
  vice versa (mutual prohibition enforced by ArchUnit)
- **`support.*`**: cross-cutting (error handling, logging, response
  envelope). Importable by all layers.

## Deployment notes

- API + Worker can run as the same Spring Boot process with profiles
  enabling/disabling `@EnableScheduling` — or as separate services if
  traffic warrants
- DB is a managed service (RDS, Supabase, Cloud SQL); migrations live
  in `src/main/resources/db/migration/` (Flyway) or via JPA DDL in
  dev-only profiles
- Cache is managed (ElastiCache, Upstash, Cloud Memorystore) — never
  run local Redis in production

## When to update this file

- A new container is added (e.g. a separate Batch service split off
  from the Worker)
- A container's technology changes (e.g. Postgres → CockroachDB)
- A dependency edge is added or removed
- An ADR lands that shifts the architecture

Changes to this diagram without a corresponding ADR are a red flag —
architecture shifts should be deliberate decisions, not incidental edits.
