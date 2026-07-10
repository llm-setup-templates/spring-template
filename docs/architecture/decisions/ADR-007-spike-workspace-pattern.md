# ADR-007 — Spike code lives at workspace root, not inside the Gradle module

Status: Accepted (via this PR)

## Context

A "spike" — Sutherland-style throwaway code to validate a hypothesis — needs to compile and run alongside the production project but must NOT be subject to the same review gates (Checkstyle, SpotBugs, ArchUnit boundaries, JaCoCo coverage).

In a Gradle multi-module project there are two natural locations for spike code:

1. **Inside the module** — a `src/spike/java/` sourceSet that the build configures via `extendsFrom main`
2. **Outside the module** — a sibling `spike/` directory at the workspace root, with its own `build.gradle`

A real recurring lesson (TruthScope BE PR #43, 2026-04 timeframe) showed that placing spike code inside the production module's `build.gradle` caused:

- Checkstyle false positives when spike code uses fields the linter flags as unused
- SpotBugs reports treating spike-only patterns (e.g. blocking I/O in main thread) as production bugs
- Configuration cache + `extendsFrom` policy violations because the spike sourceSet inherits production constraints
- 1 week of intermittent CI failures before the spike was extracted to a workspace-root directory

## Decision

**Spike code MUST live at the workspace root in a sibling `spike/` directory, not inside the production Gradle module.**

Canonical layout:

```
<workspace>/
├── <production-project>/        ← spring-template-derived project
│   ├── build.gradle
│   └── src/main/java/...
└── spike/                       ← throwaway exploration code
    ├── build.gradle             ← isolated, no extendsFrom production
    └── src/main/java/...
```

The spike module:

- Has its own `build.gradle` with the minimum dependencies needed for the experiment
- Is **excluded** from the parent project's verification loop (no `./gradlew checkstyle` enforcement, no `./gradlew test` requirement)
- Is **deleted** when the experiment ends (or graduated into production via a normal feature PR)

## Alternatives considered

### Option A: `src/spike/java/` sourceSet inside the Gradle module

Define a `spike` sourceSet with `extendsFrom main`. Run via `./gradlew spike`.

**Trade-offs**: zero filesystem changes, IDE auto-discovery. But the sourceSet inherits production-level static-analysis tasks (Checkstyle, SpotBugs) unless each task is explicitly excluded — and the exclusion list grows with every new gate.

**Rejected because**: TruthScope PR #43 lost a week to false positives; the exclusion-list ratchet has no natural stopping point.

### Option B: workspace-root `spike/` directory (this ADR)

Sibling Gradle module with isolated build script.

**Trade-offs**: one extra directory; spike build is fully separate. IDE setup needs both modules.

**Accepted because**: production gates remain pristine. Spike code reads as obviously experimental from the directory layout alone.

### Option C: status quo — put spike in `src/main/` and remove later

**Rejected because**: violates Gate 3 (Surgical Diff) of `.agents/rules/llm-behavior-gates.md`. Production code gets touched twice per spike (add, remove) for zero shipped value.

## Named exception — when spike-inside-Gradle is permitted

A spike MAY live inside the production module IF AND ONLY IF all four conditions hold:

1. The experiment requires direct access to a production package's package-private symbols (no public API exists yet)
2. Total spike LOC ≤ 50
3. The spike has a TTL — the PR introducing it includes a removal-PR link in its body, OR the spike file carries a `// SPIKE: remove by YYYY-MM-DD` comment
4. The PR is labeled `spike` (excluded from default branch protection — see ADR-003)

Outside these conditions, the workspace-root pattern is mandatory.

## Consequences

What becomes **easier**:

- CI gates (Checkstyle, SpotBugs, ArchUnit, JaCoCo) stay strict on production code without per-task spike exclusions
- Reviewers identify experimental code by its location, not by reading commit messages
- Deleting a spike is `rm -rf spike/`, not a multi-file Gradle revert

What becomes **harder**:

- IDE setup requires opening both modules (or a parent `settings.gradle` that conditionally includes `spike/`)
- Cross-module imports from spike → production require explicit dependency declarations in `spike/build.gradle`

What **new technical debt**:

- One more directory to keep clean. Spikes left running > 30 days should be either deleted or graduated. No automated enforcement; relies on PR review discipline.

## Business impact

### Cost

- Engineer time to implement: 0 (template change only — no per-project setup)
- Ongoing: one PR review checklist item ("if PR adds a spike, is it at workspace root?")

### Risk

- Blast radius of misuse: 1 week of CI flakiness (reproduced incident on PR #43)
- Mitigation: this ADR + ADR-003 branch protection's `spike` label gate

### Velocity impact

- Enables: aggressive throwaway exploration without contaminating production gates
- Does not affect: production verification loop, dependency upgrade cadence

## References

- Lesson source: TruthScope BE PR #43 (incident — spike sourceSet stuck inside Gradle module triggered FP cascade)
- Related: ADR-003 (Branch protection — `spike` label exemption), ADR-006 (LLM Behavior Gates — Gate 4 Minimum Code)
