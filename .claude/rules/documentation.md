# Documentation Rules — What to write, where to write it, in what form

This template ships four documentation modules. Core is always installed;
Reports, Briefings, and Extended are opt-in. Each module answers a
different "why write this document" question — this file is the decision
tree an agent (and a human) uses to pick the right location.

## Module map

| Module | Installed by default | Content |
|---|---|---|
| **Core** | yes | FR, RTM, ADR, RFC, C4 Level 1 overview |
| **Reports** | opt-in (`--with-reports`) | Spike tests, benchmarks, API deep dives, PAAR post-mortems |
| **Briefings** | opt-in (`--with-briefings`) | Dated, frozen meeting/talk archives (`YYYY-MM-DD/`) |
| **Extended** | opt-in (`--with-extended`) | C4 Level 2 containers, DFD, Extended Data Dictionary |

## Decision tree — "I want to write a new document"

```
Which best describes what you're about to write?

├─ A technical decision that is FINAL and will shape the code
│   → docs/architecture/decisions/ADR-NNN-<slug>.md (Accepted, append-only)
│   → If not yet final: docs/architecture/decisions/RFC-NNN-<slug>.md
│
├─ A single feature's I/O, preconditions, logic, decision table
│   → docs/requirements/FR-XX-<slug>.md (copy _FR-template.md)
│   → Add a row to docs/requirements/RTM.md
│
├─ A measurement result (load test, framework comparison, API analysis)
│   → docs/reports/<spike|benchmark|api-analysis>-YYYY-MM-DD-<slug>.md
│
├─ An incident post-mortem or deep troubleshooting write-up
│   → docs/reports/paar-YYYY-MM-DD-<slug>.md
│
├─ Materials for a specific meeting, talk, or interview
│   → docs/briefings/YYYY-MM-DD-<slug>/ (copy _template/)
│   → Frozen after the event; edits go in a follow-up folder
│
└─ Architecture big-picture (system context, containers, data flow)
   → docs/architecture/overview.md (Core, C4 Lv1)
   → docs/architecture/containers.md (Extended, C4 Lv2)
   → docs/architecture/DFD.md (Extended, data flow only)
```

## Naming rules

- **FR / NFR**: `FR-01`, `FR-02`, `NFR-01` — functional / non-functional requirements
- **ADR / RFC**: three-digit zero-padded — `ADR-001`, `ADR-042`, `RFC-007`
- **Reports**: prefix + date + slug — `spike-test-2026-04-11-fc-api-korean.md`
- **Briefings**: date-prefixed folder — `2026-04-14-professor-interview/`
- Files in template slots that are meant to be copied (not edited in place)
  are prefixed with `_` — for example `_FR-template.md`, `_ADR-template.md`.
  Remove the underscore when you copy.

## ADR / RFC lifecycle

Five states live at the top of every ADR/RFC file as
`Status: <state>`.

```
Proposed  →  Accepted  →  Deprecated
    │            │              │
    └─ Rejected  └─ Superseded by ADR-NNN
```

- `Proposed` — opened as a Draft PR; edits are free
- `Accepted` — merged to main; the file becomes **immutable** from this
  point. Future changes follow the Append-only rule below
- `Rejected` — closed without acceptance; keep the file so future
  contributors don't re-propose the same rejected idea
- `Deprecated` — the decision is no longer in force; no replacement
- `Superseded by ADR-NNN` — replaced by a newer decision. Both files
  stay on disk; the old one gains a `Superseded by ADR-NNN` header and
  a hyperlink to the successor

### Append-only rule

**Never edit an Accepted ADR to change its decision.** Write a new ADR
with the next available number, link both, and change the old ADR's
status to `Superseded by ADR-NNN`. This keeps the decision history
intact and lets anyone reading ADR-042 understand the full chain that
led to ADR-089.

Only two kinds of edit are allowed on an Accepted ADR:
1. Fixing typos or broken links
2. Updating the Status line when the decision is superseded, deprecated,
   or rejected after the fact

## RTM — Requirements Traceability Matrix

`docs/requirements/RTM.md` is a single table with one row per FR that
links the requirement across all of its artifacts:

```
| FR-XX | Summary | Issue | ADR | Component | Test | Status |
```

Update the RTM in the same PR that adds or changes an FR. If you add a
new ADR that a previously-accepted FR now depends on, add the ADR link
to that FR's row.

## Writing for LLM agents (not just humans)

An LLM agent reading these documents will use them to generate code.
That raises the stakes for two things most handwritten docs skip:

1. **Preconditions and postconditions must be machine-checkable.** If a
   Mini-Spec says "the user must be authenticated", the agent needs to
   know which check (a middleware, a server-side session lookup, a JWT
   verification call) enforces that — name the function or file
2. **Decision tables should be exhaustive, not indicative.** Cover every
   combination of conditions explicitly. The agent will generate one
   test per rule — missing rules mean missing tests

## PR obligations

Every PR should verify against this checklist — the PR template enforces
it with checkboxes:

- [ ] If the PR implements an FR, the FR file exists and the RTM row is
      updated in the same PR
- [ ] If the PR makes an architectural decision, the ADR file exists
      (Accepted) and is linked from the PR body
- [ ] If the PR is an experiment or spike, a report lives in
      `docs/reports/` and is linked from the PR body

## Don't write a document if…

- A short comment in the code would carry the same information. Files
  have a cost — they rot, they get wrong, they crowd navigation.
  Prefer a named function, a descriptive test, or a docstring
- The information is already somewhere else (the README, an existing
  ADR, a library's docs). Link instead of duplicating
- You're writing it "in case someone needs it later". Wait until there
  is a specific reader with a specific question
