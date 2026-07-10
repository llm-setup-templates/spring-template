# Requirements Traceability Matrix

> Single source of truth linking every functional requirement (FR) to
> its artifacts: GitHub issue, architectural decisions it depends on,
> the code it lives in, the tests that cover it, and its current status.

## How to use

- **Add a row** when a new FR is opened (via `.github/ISSUE_TEMPLATE/feature.yml`)
- **Update the row** in the same PR that implements or changes the FR
- **Never delete a row**; if an FR is abandoned, change its status to
  `Deprecated` and add a note in the FR file
- Non-functional requirements (NFRs) go in a separate section at the
  bottom. Same rules apply.

## Status values

| Value | Meaning |
|---|---|
| `Draft` | FR file exists, AC not finalized |
| `Design` | AC agreed; ADRs being written |
| `Implementing` | PR open, tests being added |
| `Done` | Merged, tests passing, RTM row complete |
| `Deprecated` | No longer in scope — keep row for history |

## Functional requirements

<!-- Example row (kept in this comment so it never pollutes the live table):
| FR-ORDER-001 | (example) cancel an order | #0 | — | `src/main/java/com/example/app/order/CancelOrderService.java` | TC-ORDER-001 `src/test/java/com/example/app/order/CancelOrderServiceTest.java` | Done |
-->

| FR ID | Summary | Issue | ADR | Component(s) | Test(s) | Status |
|---|---|---|---|---|---|---|

## Non-functional requirements

<!-- Example row:
| NFR-PERF-001 | (example) p95 API latency | < 300 ms | k6 spike test (`docs/reports/spike-test-YYYY-MM-DD-api-latency.md`) | — | Draft |
-->

| NFR ID | Summary | Target | Measurement | Owner | Status |
|---|---|---|---|---|---|
