# ADR-NNN: <decision in one declarative sentence>

> **Copy this file.** Rename to `ADR-NNN-<slug>.md`, remove the leading
> underscore. Open as a Draft PR with `Status: Proposed`. Merging to
> main flips the status to `Accepted` and this file becomes
> **immutable** (see `README.md` § Append-only rule).

---

- **Status**: Proposed
- **Date**: YYYY-MM-DD
- **Deciders**: @github-handle, @github-handle
- **Related**: RFC-NNN (if this ADR summarizes an RFC), ADR-NNN (if this supersedes one)

## Context

What problem does this decision solve? Give concrete evidence: a
measurement, an incident, a library version gap, a regulatory
requirement. Cite dates, PRs, or issues. Context should make it obvious
that a decision is needed — if a reader can ask "why now?" after
finishing this section, the context is too thin.

## Decision

One or two sentences. In plain language, state what was decided. The
rest of this document exists to defend this sentence.

> Example: "We will use Redis as a distributed session cache behind
> our API services. Local in-process caches will be removed."

## Alternatives considered

List every option that was on the table, including the status quo.
Each option gets: one line of description, one paragraph of trade-offs,
one line on why it was rejected.

### Option A: <short name>

Describe briefly. What would this have looked like?

**Trade-offs**: pros and cons.

**Rejected because**: the single strongest reason.

### Option B: <short name>

...

### Option C (status quo): keep the current implementation

...

## Consequences

What becomes **easier** after this decision?

- ...

What becomes **harder** after this decision?

- ...

What **new technical debt** are we taking on? Every ADR creates at
least some. Name it explicitly so we remember to pay it down.

- ...

## Business impact

Translate the decision for non-technical stakeholders. Quantify every
bullet that can be quantified.

### Cost

- Infrastructure: $X / month additional
- Vendor / license: $Y one-time
- Engineer time to implement: N person-weeks
- Ongoing maintenance: N hours / sprint

### Risk

- Blast radius if the decision turns out wrong: <users affected>, <rollback time>
- Mitigations: <fallback plan>, <feature flag>, <gradual rollout>

### Velocity impact

- What this **enables** in the next quarter: ...
- What this **blocks** or delays: ...
- What this **does not affect**: ...

## Implementation notes (optional)

Pointers to the code that embodies this decision. Keep this short —
detailed integration instructions belong in a PR description or a FR
file, not here.

- Entry point: `src/shared/...`
- Configuration: `.env` variables `X_*`, `Y_*`
- Migration plan: <link to plan>, <deadline>

## References

- RFC-NNN (if applicable)
- External docs, papers, blog posts
- Related ADRs: ADR-NNN, ADR-NNN
