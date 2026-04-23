# ADR-001: Pin JaCoCo coverage baseline at 70% line + 70% branch with 7 excludes and 3 guards

---

- **Status**: Accepted
- **Date**: 2026-04-23
- **Deciders**: @KWONSEOK02
- **Related**: (none — first ADR in this template)

## Context

This template derives an AI-agent-driven Spring Boot 3 scaffold. Until Phase 11, JaCoCo was not installed at all — the `build.gradle.kts` had neither the plugin nor any coverage verification. Derived repositories therefore shipped with **zero coverage signal** on day-0 CI, which silently defeats the "LLM agent writes code, CI enforces quality" design intent.

Phase 10 (typescript-template) pinned Jest coverage at 70% as a starter baseline. Phase 11 decides the Java/Spring equivalent. The decision has to survive three constraints simultaneously:

1. **Day-0 green**: an empty scaffold (no real controllers / services yet) must still pass `./gradlew check` on the very first CI run. A high threshold with narrow excludes would fail here.
2. **LLM agent autonomy**: the SETUP.md prompt instructs the agent to treat CI green as the completion signal. If the threshold traps the agent into multi-hour coverage expansion before any product code exists, the setup UX breaks.
3. **Long-term quality anchor**: once real business logic lands, the threshold must not be so low that it anchors teams into neglecting tests.

Note on prior documentation: earlier template versions mistakenly claimed the project enforced "6 rules" or "10 rules" in ArchUnit; the actual `@ArchTest`-annotated field count is **12**. Phase 11 corrects this drift alongside the JaCoCo decision (see `examples/archunit/ArchitectureTest.java` line 19 JavaDoc).

## Decision

Pin JaCoCo at **70% line + 70% branch** coverage verification in `examples/build.gradle.kts`, scoped by **7 excludes** (boilerplate + framework glue + error-handling support), and counter-balance the anchoring risk with **3 explicit guards** that make raising the threshold the documented default trajectory.

## Alternatives considered

### Option A (chosen): 70% line + 70% branch, excludes 7개, guards 3개

Pin both counters at 0.70. Exclude `config/**`, `entity/**`, `dto/**`, `Application`, `support/error/**`, `architecture/**`, `core/api/support/**` (`ApiControllerAdvice` package). Add three guards: a one-line comment in `build.gradle.kts` stating the baseline rationale, an Appendix section in `SETUP.md` (§ Coverage Threshold Adjustment) that documents the upgrade path, and excludes that restrict measurement to pure business logic.

**Trade-offs**: Day-0 green is guaranteed; Phase 10 consistency is preserved; the LLM agent never hits a coverage wall during scaffold; anchoring-to-70% risk is real but mitigated by the guards.

### Option B: 80% line + 80% branch

Match industry "solid" coverage expectations immediately. Stricter signal from day one.

**Rejected because**: on a day-0 scaffold that has only `Application.java` + minimal config, excludes alone cannot carry coverage to 80% — the scaffold would fail its own CI before any product code lands, violating the "empty directory → CI green" contract.

### Option C: line 80% / branch 60% asymmetric

Relax branch coverage since branches depend on conditional logic that early scaffolds lack, while keeping line coverage strict.

**Rejected because**: the asymmetry adds explanation complexity for no clear day-0 benefit, and LLM-agent-facing documentation (SETUP.md, CLAUDE.md) should keep threshold logic learnable in one sentence. Relaxing only branch also fails the scaffold for the same reason as Option B.

See `.plans/llm-setup/11-spring-template-hardening/DISCUSS.md § Q2` for the full Trade-off comparison table (Day-0 green / Phase 10 parity / LLM auto-run / beginner positioning / long-term signal / explanation complexity).

## Consequences

What becomes **easier**:

- LLM agents scaffolding a new Spring Boot app via SETUP.md see CI green on the first push without manual coverage work.
- Derived repos inherit a coverage floor and a documented upgrade trajectory, not a "coverage TODO" note that rots.
- Phase 10 (TS) and Phase 11 (Spring) coverage philosophy is aligned at 70% starter baseline — one ADR reference explains both.

What becomes **harder**:

- Teams that already have a mature Spring codebase and expect 80% strict will need to raise the threshold explicitly (see SETUP.md § Coverage Threshold Adjustment).
- The 70% number can become an anchor — teams may feel "we hit the bar, move on" even when 85% would be readily achievable.

**New technical debt taken on**: the anchoring risk above. Mitigation is explicit and documented (guards 1-3), but it remains a cultural risk that tooling alone cannot fix.

## Business impact

### Cost

- Infrastructure: $0 additional (JaCoCo is bundled with Gradle, reports run in the existing CI runner time window)
- Vendor / license: $0
- Engineer time to implement: ~2 person-hours (this Phase 11 PR) + per-derived-repo scaffold cost unchanged
- Ongoing maintenance: review threshold in ADR supersede when team size, audit posture, or production status changes

### Risk

- Blast radius if wrong: derived repos carry an under-enforced coverage floor; correction is a single-line edit in `build.gradle.kts`. Rollback time: minutes.
- Mitigations: guards 1-3 document the upgrade path; this ADR becomes the reference point for any future supersede.

### Velocity impact

- **Enables**: LLM agents complete scaffold-to-green faster; Phase 10 / 11 parity removes cognitive overhead for teams running both templates.
- **Blocks or delays**: nothing measurable — teams that want 80% from day one can raise the threshold in one commit using the SETUP.md § Coverage Threshold Adjustment guide.
- **Does not affect**: existing CheckMate-backend or other derived repos that already have their own JaCoCo configuration — this template's baseline is a starting point, not a ceiling.

## Implementation notes

- Entry point: `examples/build.gradle.kts` — the `tasks.jacocoTestCoverageVerification { violationRules { ... } }` block.
- Excludes list: `**/config/**`, `**/entity/**`, `**/dto/**`, `**/Application`, `**/support/error/**`, `**/architecture/**`, `**/core/api/support/**`. Each exclude corresponds to a package whose classes are either framework-generated, pure data carriers, or ArchUnit / error-handling glue that is not business logic.
- CI integration: `examples/ci.yml` Coverage step runs `./gradlew jacocoTestReport jacocoTestCoverageVerification` between the Test step and the Build step (fail-fast before shipping artifacts).
- Regression guards: `validate.sh` V9e (ArchUnit rule count = 12) and V17 (dependabot.yml presence) added in this same PR; they do not enforce coverage itself but prevent future drift in adjacent facts.
- Raising the threshold: edit `violationRules` → update both `minimum` values (LINE and BRANCH). Lowering below 70% requires superseding this ADR with a new ADR.

## References

- Phase 10 (TypeScript hardening) — Jest coverage 70% baseline: https://github.com/llm-setup-templates/typescript-template/pull/11
- `.plans/llm-setup/11-spring-template-hardening/DISCUSS.md` § Q2 — Alternatives Trade-off comparison table
- `.plans/llm-setup/11-spring-template-hardening/PLAN.md` (rev.3) — Task T1 / T9 implementation and guards
- `docs/architecture/decisions/README.md` — ADR 5-state lifecycle contract (this ADR will be immutable from merge onward per Append-only rule)
