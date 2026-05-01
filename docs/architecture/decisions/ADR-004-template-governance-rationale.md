# ADR-004: Template Governance Rationale -- Why not Copier / Projen / cookiecutter for 14a-bis

> Status: Accepted (per-template Date)
> Responsible: @gs07103
> Related: ADR-003 (Branch Protection), Phase 14a CRITIQUE.md Revision trigger 2026-11-01, 14a-bis CRITIQUE.md Differentiation axis

<!-- POLICY-BEGIN -->

## Context

Phase 14a-bis operationalizes Phase 14a Section 5 plan-review-deep.md cross-drift policy: 5-line meaning checklist + 3-axis (Flexibility / Universality / Convention precedence) reified in (a) plan-review-deep.md Section 5, (b) SETUP.md Phase E hook body, (c) Phase E PR template. Cross-template drift is enforced via V_drift CI guard (Tier 1 keyword + line count + negation auto) + Tier 2 manual SHA256 hash equality.

Three ecosystem alternatives exist for this governance class:
1. **Copier** -- `copier update` merges upstream template changes into existing projects automatically.
2. **Projen** -- "code as source of truth"; TypeScript class hierarchy generates files; massive cross-repo updates by re-synthesis.
3. **cookiecutter** -- `pre_gen_project` / `post_gen_project` hooks for fail-closed validation.

## Decision

14a-bis stays on plain markdown + bash V_drift CI guard. Migration to Copier / Projen / cookiecutter is **deferred** to the 2026-11-01 Phase 14a Revision trigger gate.

## Consequences

- **Positive**: minimal-change governance, 14a Q3=C "1 PR per repo" pattern preserved, no migration burden during low-usage phase.
- **Negative**: cross-template drift detection is bolted onto markdown rather than integrated. Ecosystem tools (Copier `update`, Projen synthesis) solve this at the root.
- **Risk**: bus-factor-1 maintainer skips Tier 2 manual SHA256 review; semantic drift via Q1=B prose freedom uncaught by Tier 1 (mitigated partially by negation-marker probe in V_drift Step 5).

## Alternatives considered

### Alternative A: Adopt Copier
- Pro: `copier update` solves cross-template drift natively. Source: [Project Templating Philosophies: Projen vs Copier](https://mhdez.com/notes/project-templating-philosophies-projen-vs-copier/) -- "killer feature template updates. If the upstream template changes, copier update merges the diff into your existing project."
- Con: migration burden (3 templates retrofit) during 0-external-usage phase.
- Verdict: deferred to 2026-11-01 gate.

### Alternative B: Adopt Projen
- Pro: "code as source of truth" eliminates byte-identical concern entirely. Source: [mhdez.com Projen vs Copier](https://mhdez.com/notes/project-templating-philosophies-projen-vs-copier/) -- "files are not the source of truth; the code is... every repository using the same base class will have an identical configuration, and it allows for massive updates across an organization simply by updating the shared Projen library version and re-synthesizing the projects."
- Con: highest migration cost (3 stacks integrate Projen base class); 1 maintainer.
- Verdict: deferred to 2026-11-01 gate (parked as remedy in 14a-bis CRITIQUE).

### Alternative C: Adopt cookiecutter
- Pro: `pre_gen_project` hook precedent already cited in plan-review-deep.md Section 6. Source: [Cookiecutter advanced hooks](https://cookiecutter.readthedocs.io/en/stable/advanced/hooks.html) -- fail-closed `pre_gen_project` / `post_gen_project` pattern.
- Con: Phase 14a CRITIQUE Revision trigger uses cookiecutter equivalence as the kill condition -- adopting it now races against own kill condition.
- Verdict: deferred until 14a Revision trigger 2026-11-01 evaluation.

## Revision trigger (inherited from Phase 14a CRITIQUE.md verbatim)

**2026-11-01** -- 6-month maintenance review gate.
- Actual usage signal observed (LLM agent fork/clone/issue OR human developer adoption) -> [GREEN] PROCEED. ADR-004 stays.
- Neither observed AND cookiecutter equivalence demonstrated -> [RED] KILL. Archive 3 templates, migrate users to cookiecutter or successor. **14a-bis collapses with 14a parent -- do not reinforce.**
- Neither observed AND cookiecutter equivalence NOT demonstrated -> [YELLOW] hold for next gate.

This 14a-bis ADR-004 has no independent kill condition: 14a-bis is a child of 14a CRITIQUE verdict.

<!-- POLICY-END -->

## Implementation Status (per-template mutable)

- Status: Accepted
- Date: 2026-05-01
