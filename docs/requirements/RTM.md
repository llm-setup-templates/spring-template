# Requirements Traceability Matrix

> Single source of truth linking every requirement — functional (FR) and
> non-functional (NFR) — to its artifacts: GitHub issue, architectural
> decisions it depends on, the API it exposes, the code it lives in,
> the tests that cover it, and its current status.

## Status values

| Value | Meaning |
|---|---|
| `Draft` | FR file exists, AC not finalized |
| `Design` | AC agreed; ADRs being written |
| `Implementing` | PR open, tests being added |
| `Done` | Merged, tests passing, RTM row complete |
| `Deprecated` | No longer in scope — keep row for history |

## Domain prefixes

Uppercase abbreviations; each domain numbers its IDs independently.

| Prefix | Meaning |
|---|---|
| `ORDER` | (example) order management — replace with your own domains |

## How to use

- Add a row when an FR issue is opened; update it in the same PR that
  implements or changes the FR. Never delete a row — set Status to
  `Deprecated` instead, and never reuse a retired number.
- Multiple values in Issue / API / Component(s) / Test(s) are allowed,
  comma-separated. Any path you write must exist in this repo
  (checked by `V_rtm` in validate.sh), except on `Deprecated` rows,
  which keep their historical paths even after the code is gone.

| Column       | Format                                             | Required when |
|--------------|----------------------------------------------------|---------------|
| FR ID        | `FR-{DOMAIN}-{NNN}` (NFR rows: `NFR-{CATEGORY}-{NNN}`) | always    |
| Summary      | one line                                           | always        |
| Issue        | `#NNN`, comma-separated                            | optional      |
| ADR          | `ADR-NNN`                                          | optional      |
| API          | operationId (camelCase handler name), or `n/a`     | optional      |
| Component(s) | backticked repo-relative file path(s)              | Status = Done |
| Test(s)      | `TC-{DOMAIN}-{NNN}` (recommended) plus backticked test path(s) | Status = Done |
| Status       | Draft / Design / Implementing / Done / Deprecated  | always        |
| Owner        | `@handle`, or `—`                                  | optional      |
| Notes        | NFR target and measurement, exclusion reason, etc. | optional      |

Domain prefixes are defined in the table above — `ORDER` in examples is a
placeholder; define your own.

## Requirements

<!-- Example rows (kept in this comment so they never pollute the live table):
| FR-ORDER-001 | (example) cancel an order | #0 | — | cancelOrder | `src/main/java/com/example/app/order/CancelOrderService.java` | TC-ORDER-001 `src/test/java/com/example/app/order/CancelOrderServiceTest.java` | Done | — | — |
| NFR-PERF-001 | (example) p95 API latency | — | — | n/a | — | — | Draft | — | Target: < 300 ms; measurement: k6 spike test (`docs/reports/spike-test-YYYY-MM-DD-api-latency.md`) |
-->

| FR ID | Summary | Issue | ADR | API | Component(s) | Test(s) | Status | Owner | Notes |
|---|---|---|---|---|---|---|---|---|---|
