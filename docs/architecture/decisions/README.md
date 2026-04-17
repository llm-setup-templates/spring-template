# Architectural Decisions — ADRs and RFCs

Two complementary formats live here:

| | **RFC** | **ADR** |
|---|---|---|
| Purpose | Propose and debate | Record the final decision |
| State | Proposed (lives in a Draft PR) | Accepted (merged to main) |
| Mutability | Edit freely during debate | **Immutable** after Accepted |
| File | `RFC-NNN-<slug>.md` | `ADR-NNN-<slug>.md` |
| When to use | Complex trade-offs, multiple stakeholders, non-obvious implications | Final decisions that shape code |

An RFC often graduates to an ADR: after the RFC is debated and a
direction is agreed, summarize the decision as an ADR (new file, new
number). The RFC stays here as historical context.

## Lifecycle states

Every ADR and RFC file has a `Status:` field at the top. Five states:

```
            ┌──────────────┐
            │  Proposed    │  ← open as Draft PR, free to edit
            └──────┬───────┘
                   │ merge to main
                   ▼
            ┌──────────────┐
            │  Accepted    │  ← immutable; decision is in effect
            └──────┬───────┘
                   │
     ┌─────────────┼─────────────┬─────────────┐
     ▼             ▼             ▼             ▼
┌─────────┐  ┌──────────┐  ┌──────────────┐   (remains Accepted)
│Rejected │  │Deprecated│  │Superseded by │
│         │  │          │  │  ADR-NNN     │
└─────────┘  └──────────┘  └──────────────┘
(no longer    (no longer    (replaced by a
in force —    in force, no   newer ADR)
was never     replacement)
accepted)
```

## Append-only rule

**Never edit an Accepted ADR to change its decision.** Doing so destroys
the history of how the architecture evolved and confuses anyone who
encounters code that predates the edit.

Instead:

1. Write a **new** ADR with the next available number
2. In the new ADR's Context section, reference the old one and explain
   what changed and why
3. Edit the old ADR's `Status:` line to `Superseded by ADR-NNN` and add
   a single-line link at the top pointing to the successor
4. Nothing else in the old ADR changes

The only edits allowed to an Accepted ADR are:
- Fixing typos or broken links
- Updating `Status:` when superseded, deprecated, or rejected after
  the fact
- Adding a single-line `> Superseded by ADR-NNN: <link>` banner

## Numbering

- Sequential, zero-padded to three digits: `001`, `042`, `127`
- Never reuse a number. If an ADR is rejected or withdrawn, its number
  is retired and the file stays (with `Status: Rejected`)
- RFCs and ADRs use **separate** number sequences: `RFC-001`, `RFC-002`
  and `ADR-001`, `ADR-002` can coexist

## Naming slug

After the number, add a kebab-case slug describing the decision:

- ✅ `ADR-042-use-redis-for-session-cache.md`
- ❌ `ADR-042.md` (no slug — hard to scan a file list)
- ❌ `ADR-042-redis.md` (too vague)

## Business impact section — required for ADRs

ADRs have real business consequences (cost, risk, team velocity). The
template's **Business impact** section forces the author to translate
the technical decision into those terms. This keeps ADRs legible to
PMs, founders, and future-you.

See `_ADR-template.md` for the canonical structure and
`.claude/rules/documentation.md` § ADR lifecycle for the full ruleset.
