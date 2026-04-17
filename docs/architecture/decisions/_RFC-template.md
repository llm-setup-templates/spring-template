# RFC-NNN: <proposal in one sentence>

> **Copy this file.** Rename to `RFC-NNN-<slug>.md`, remove the leading
> underscore. Open as a Draft PR so reviewers can comment
> asynchronously. When consensus is reached, summarize the outcome as
> an ADR (separate file, new number) and close this RFC.

---

- **Status**: Proposed
- **Author**: @github-handle
- **Reviewers requested**: @github-handle, @github-handle
- **Target decision date**: YYYY-MM-DD
- **Related**: ADR-NNN (predecessor, if any)

## Summary

One paragraph: what are we proposing, why now. A reader should be able
to stop after this section and know whether they need to read further.

## Motivation

What triggered this RFC? A metric that crossed a threshold? A recurring
incident? A deadline? A library deprecation? Make the urgency concrete.

## Ranked priorities

> **Required section.** The most-common RFC failure mode is "everyone
> agrees the loudest option is best." These priorities, written up
> front, keep the discussion anchored in the problem we're solving.
> Each option below will be evaluated against these priorities in the
> Matrix section.

1. **Priority 1** (must-have): ...
2. **Priority 2** (must-have): ...
3. **Priority 3** (should-have): ...
4. **Nice-to-have**: ...

## Proposed solution

Describe the solution you're advocating for. Include:

- Architecture sketch (Mermaid is fine)
- Concrete API / interface / schema changes
- Migration path — how do we get from today to there?
- Rollback plan — if we ship this and it fails, how do we revert?

## Alternatives

### Option A: <name>

Short description. Ranked-priority fit:

- Priority 1: 🟢 / 🟡 / 🔴 — one-line justification
- Priority 2: 🟢 / 🟡 / 🔴 — one-line justification
- Priority 3: 🟢 / 🟡 / 🔴 — one-line justification

Cost: ... Risk: ... Effort: ...

### Option B: <name>

...

### Option C (status quo): do nothing

What happens if we don't act? This option is **always** on the table
and its rejection must be justified.

## Matrix

| | Priority 1 | Priority 2 | Priority 3 | Cost | Risk | Effort |
|---|---|---|---|---|---|---|
| Option A | 🟢 / 🟡 / 🔴 | ... | ... | $ / $$ / $$$ | Low / Med / High | N weeks |
| Option B | ... | ... | ... | ... | ... | ... |
| Option C (status quo) | ... | ... | ... | $0 | ... | 0 weeks |

## Open questions

Items reviewers should weigh in on. Number them so comments can
reference them:

1. ...
2. ...

## Decision criteria

What would make us pick one option over another? Name the measurable
signal, not "whichever feels right":

- If we can ship in under 3 weeks, prefer Option A
- If existing load testing shows p95 > 500ms under Option B, reject it
- ...

## Outcome

*Filled in at the end of the discussion, before promoting to an ADR.*

- **Decision**: ...
- **Follow-up ADR**: ADR-NNN-<slug>.md
- **Rejected options**: A, C (with brief reason for archive)
