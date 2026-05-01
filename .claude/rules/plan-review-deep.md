# plan-review-deep.md — Cross-cutting governance

> Source of truth for `/pf plan-review-deep` runs in this template.
> Authored by Phase 14a (2026-05-01). **byte-identical** across `spring-template` (canonical), `python-template`, `typescript-template`.
> Hard review limit: **300 lines**. Weighted target: **200**.

## Table of Contents

1. F1 4 subfacet acceptance checklist
2. V0a / V0e / V_seed schema contract
3. §0 schema 5 strict items
4. Ratchet template
5. Phase E entry rubric
6. Phase 13c case study + external references
7. Critical-0 convergence loop policy
8. Phase 14b / 14c stack policy

---

## 1. F1 4 subfacet acceptance checklist

The 4 subfacets of **F1 (Failure-First Discipline)** — top-3 abandonment-cost mindset principle from `docs/superpowers/specs/2026-04-30-programming-principles-to-templates/step4-application-matrix-detailed.md`.

### F1.a Reproducible Failure
A failure that can be reproduced deterministically by another reviewer running the same command on the same source state. No "works on my machine".
**Verify**: capture exact command + working tree SHA + last 20 lines of stderr/stdout in the PR description.

### F1.b Staged Gate
The failure surfaces at a specific lifecycle stage (`clone` / `scaffold` / `verify` / `ci`) before downstream stages run. No silent late surface.
**Verify**: each `validate.sh` echo header `=== F1.b ... ===` precedes the gate it is gating; `ci` step that runs `validate.sh` exits non-zero on failure.

### F1.c Immutable Verification
The verify command and its expected exit code do not depend on local mutable state (timezone, locale, date, random network state). Same input → same output.
**Verify**: re-run the verify chain twice in a row; both must produce byte-identical stdout (modulo absolute timestamps that are masked in `awk`/`sed` filters).

### F1.d Full-Solution Verification
The verify covers the full solution path, not just a unit. A passing F1.d means the deliverable is shippable end-to-end, not just compilable.
**Verify**: at least one happy-path E2E or integration check is part of the verify chain. Unit-only verify is insufficient.

PASS counter convention: each subfacet emits a single `=== F1.x ... ===` header echo from `validate.sh`; CI counts headers via `grep -cE 'echo[[:space:]]+"=== F1\.[a-d]' validate.sh -eq 4`.

---

## 2. V0a / V0e / V_seed schema contract

> [Reified by Task T2 in this PR. The schema below is the binding contract between this rules file and `validate.sh` of all 3 templates — no deviation without ratchet (Section 4).]

### V0a Self-monolithic guard

### V0e §0 anchor guard

### V_seed Worked example seed

---

## 3. §0 schema 5 strict items

> [Reified by Task T2 in this PR. The 5 items below are the contract between `SETUP.md` of all 3 templates and `V0e`.]

(a)
(b)
(c)
(d)
(e)

---

## 4. Ratchet template

> [Reified by Task T3 in this PR. Trigger conditions, standard PR body block, and Reality Lens re-verification rules.]

---

## 5. Phase E entry rubric

> [Reified by Task T3 in this PR. 14a-bis 5-line meaning checklist + 3-axis (Flexibility / Universality / Convention precedence) summary + cross-drift policy.]

---

## 6. Phase 13c case study + external references

Phase 13c (TypeScript clone+script architecture, merged `c8f4a97` on 2026-04-26 in `llm-setup-templates/typescript-template`) is the canonical worked example of the F1-discipline + scaffold/verify split + 3-tier validation that `V0a/V0e/V_seed` codify. Phase 13c plan-review-deep (Round 1-3, Critical-0 convergence) demonstrated that the Reality Lens catches `examples/.../seed/` directory drift that Contract+Completeness Lenses miss.

**External references** (necessity grounded outside this Phase, per CRITIQUE.md Necessity remedy):

- [Thoughtworks — TDD as a scaffold for a better product](https://www.thoughtworks.com/insights/blog/testing/tdd-as-a-scaffold-for-a-better-product): TDD as mindset/process/tool, not a single tactic.
- [Spec-driven development — Wikipedia](https://en.wikipedia.org/wiki/Spec-driven_development): specification as executable contract; aligns with V0e/V_seed fail-closed semantics.
- [Cookiecutter — advanced hooks](https://cookiecutter.readthedocs.io/en/stable/advanced/hooks.html): fail-closed `pre_gen_project` / `post_gen_project` pattern; precedent for V0a/V_seed exit-1-on-violation.

---

## 7. Critical-0 convergence loop policy

A `plan-review-deep` Round converges when **(a) Critical issues = 0** + verdict ∈ {PROCEED, PROCEED-WITH-CONDITIONS}, OR **(b) Round 5 (max)** is reached and the user explicitly elects escalate option (b) "Critical을 ADR로 박제 후 PROCEED-WITH-CONDITIONS".

Each round must rotate the Lens. Reference: `~/.claude/skills/project-flow/planning.md` §"Mode: plan-review-deep" — full rule including 4 Lens definitions (Contract / Completeness / Reality / Runtime Contract). New-Phase canonical cycle: Contract → Completeness → Reality → Runtime Contract → user-selected (Phase 14a R1-R5 confirmed this cycle, R5 user-selected Reality refine for baseline correction).

---

## 8. Phase 14b / 14c stack policy

After Phase 14a (top-3 mindset principles F1 + F2 + F4 + F12 → landed across 3 templates) merges, the next stacks open in this order. Both must follow Section 4 (Ratchet template) for any same-PR threshold raise.

### Phase 14b (compromise reduction + F7 3-tier expansion)
- F5 / F8 / F10 layered additions per `step4-application-matrix-detailed.md`.
- F7 3-tier validation expansion: `V_seed` → `V_seed-l1 / l2 / l3` per archetype maturity (typescript Tier1=F1.c / Tier2=F1.b / Tier3=F1.a precedent).
- Same-PR ratchet allowance: ≤10% over Phase 14a-locked threshold per template (see Phase 14a PLAN.md per-template threshold rev.6 R5-corrected).

### Phase 14c (deferred F11 + remainder)
- F11 (Hidden Behavior Coverage) — deferred from 14a per Q5 LOCK.
- Final cleanup of Phase 14a compromises (CX-10 spring V_seed `// TODO` broad pattern, R3-09 python `routers/` V_seed addition, etc.).

Phase 14a-bis (3-axis Phase E entry rubric, Section 5) is a **separate Phase**, not a 14b/14c stack item.
