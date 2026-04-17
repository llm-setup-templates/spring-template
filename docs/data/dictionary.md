# Data Dictionary

> Extended Data Dictionary — every named data element in the system
> linked to the **live JPA entity + Bean Validation annotations** that
> define it. The code is the source of truth; this file is the index
> into the code.

## How this file is structured

Each row in the table points to a JPA entity class (or a DTO record).
The class is authoritative for the type, constraints, and default
values via Bean Validation annotations (`@NotNull`, `@Email`,
`@Size`, `@Pattern`, `@Column(unique=true)`, etc.). This file adds
the **business-level** context (ownership, policy, rationale) that
doesn't belong in the code.

**Never duplicate field definitions here.** If a reader needs the
exact type or regex, they follow the link to the entity. Duplication
is what makes data dictionaries rot.

## Data elements

| Element | Entity / DTO class | DFD flow | Owner | Policy notes |
|---|---|---|---|---|
| `User` | `storage/db/entity/UserEntity.java` | EXT-01 → 1.0 | auth-team | PII — never logged; `@Email` + `@Size(max=255)` |
| `Session` | `storage/db/entity/SessionEntity.java` | 1.0 → D1 | auth-team | 24h TTL (`expiresAt` column, cleanup scheduler) |
| `Article` | `storage/db/entity/ArticleEntity.java` | EXT-02 → 2.0 | content-team | cached 1h via `@Cacheable` on service method |

## Notation carry-over from structured analysis

The 1978 DeMarco notation (`= + [ | ] { } ( ) ** **`) isn't used
directly — Bean Validation annotations express all of it more
clearly:

| DeMarco | Bean Validation / JPA equivalent |
|---|---|
| `=` definition | `@Entity class X { ... }` or `record XDto(...)` |
| `+` composition | fields of the entity / record |
| `[ a \| b ]` selection | `@Enumerated(EnumType.STRING)` on an enum field |
| `{ a }` iteration | `@OneToMany` / `List<A>` |
| `(a)` optional | nullable field, no `@NotNull`, or `Optional<A>` in DTO |
| `** comment **` | Javadoc on the field |

Business rules that annotations can't express (e.g. "balance must
equal sum of transactions") belong as JPA `@PrePersist` /
`@PreUpdate` callbacks or service-layer invariant checks with
documented rationale.

## Cross-cutting policies

Not every field needs a table row — but policies that apply across
many fields do:

- **Timestamps**: `BaseTimeEntity` abstract class (see
  `examples/.../support/` or equivalent) provides `createdAt` +
  `updatedAt` with `@CreationTimestamp` / `@UpdateTimestamp`.
  All UTC; never trust client-supplied timestamps
- **UUIDs**: all primary IDs use
  `@GeneratedValue(strategy = GenerationType.UUID)` unless an ADR
  documents an exception (e.g. `Member` reuses Supabase auth UUID)
- **Currency**: store as `BigDecimal` with fixed `scale=2` — never
  `double` or `float`. Format at the API boundary, not in the domain
- **Email**: normalized lowercase on write (JPA `@PrePersist`),
  case-sensitive on display
- **Enums**: always `@Enumerated(EnumType.STRING)` — ordinal
  persistence is banned (an added enum value shifts existing rows)

## When to add a row

- A new domain-level entity appears in the system
- A field's **policy** changes (even if the Java type doesn't)
- A field crosses a trust boundary (PII, payment, auth token) and
  needs handling rules documented

## When NOT to add a row

- Every internal-only helper DTO — those are local to a controller
  or service
- Entity internal columns that are purely persistence plumbing
  (`version`, `deletedAt`, etc.) — the `BaseTimeEntity` convention
  covers them
- Derived / computed fields that don't persist — document them in
  the FR file, not here
