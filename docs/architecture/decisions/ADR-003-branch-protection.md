# ADR-003: Branch Protection and Self-Merge Cooling Period

<!-- POLICY-BEGIN -->
## Policy

### Branch protection rules (main)

- Direct commits to `main` are forbidden -- all changes go through a PR.
- A PR must pass CI (Static verification + scaffold-e2e matrix) before merge.
- At least 1 approving review is required, OR the maintainer self-merges under the cooling-period rule below.

### Self-merge cooling period (24 hours)

For solo-maintained templates (bus factor 1 -- see Phase 14a `CRITIQUE.md`), a maintainer may self-merge their own PR only after a 24-hour cooling period from PR open time. Rationale: the cooling period gives the author a chance to revisit the change with fresh eyes, catching the obvious mistakes that no second pair of eyes can flag.

Exception: a hotfix PR that resolves a blocking CI failure on `main` may bypass the cooling period. The bypass MUST be documented in the PR description (one line is enough: "bypass cooling period -- main is red, fix is mechanical").

### Maintenance review schedule

Every 6 months, the maintainer reviews this template repo for:

- Cumulative ratchet drift (V0a / V_seed thresholds raised since the prior review).
- Active vs reserved archetypes (any reserved archetype should be activated or removed if stale > 12 months).
- ADR rot (any ADR whose Status is Accepted but whose policy is no longer practiced).

Next review: **2026-11-01**.

### Responsible maintainer

- @gs07103 (Phase 14a author).

### Revision trigger (kill / pivot / proceed-with-conditions)

This template's `CRITIQUE.md` 🟡 PROCEED-WITH-CONDITIONS verdict (Necessity WEAK) ages out on 2026-11-01. At that date:

- If actual usage signal IS observed (an LLM agent has forked / cloned the template, or a human developer has adopted it for a real project), OR the `cookiecutter` `post_gen_project` hook pattern has NOT demonstrated equivalent V0a / V_seed coverage: PROCEED. Update `CRITIQUE.md` Status from 🟡 to 🟢.
- If NEITHER signal is observed AND `cookiecutter` hooks demonstrate equivalent coverage: 🟡 -> 🔴 KILL. Archive this template and migrate users to `cookiecutter` (or successor tooling).
<!-- POLICY-END -->

## Status

| Field | Value |
|---|---|
| Status | Accepted |
| Date | 2026-05-01 |
| Phase | 14a (Wave 4 / T10) |

## Context

Phase 14a `CRITIQUE.md` (deep-feature-critique 🟡 PROCEED-WITH-CONDITIONS, 2026-05-01) flagged three concerns this ADR addresses:

- **Bus factor 1** (Critical): solo maintainer (@gs07103). Self-approval is structurally unsound -- a single mistake has no second-pair-of-eyes recourse. Mitigated by the 24h cooling period and the 6-month review schedule above.
- **Necessity WEAK**: external references (Thoughtworks TDD, SDD Wikipedia, Cookiecutter hooks -- see `.claude/rules/plan-review-deep.md` Section 6) ground the rationale, but the Phase's actual user adoption is unknown until 2026-11-01. The Revision trigger above provides the kill / pivot / proceed gate.
- **Usage UNKNOWN**: no LLM agent has yet forked or cloned the template at Phase 14a merge time. The 6-month review checks this signal.

## Consequences

Positive:

- Self-approval mistakes get a 24h cooling-off buffer.
- Schedule-driven maintenance review catches dead archetypes and threshold drift.
- Explicit kill-switch (Revision trigger) prevents indefinite low-value maintenance of a template no one uses.

Negative:

- 24h cooling delays even minor changes. Mitigated by the hotfix bypass for CI-blocking issues.
- 6-month review is a recurring cost. Mitigated by the review checklist being short (3 items).

## References

- `.claude/rules/plan-review-deep.md` Section 6 (external references: Thoughtworks TDD, SDD Wikipedia, Cookiecutter hooks).
- Phase 14a `CRITIQUE.md` (Necessity / Bus factor / Revision trigger).
- Phase 14a `PLAN.md` rev.7 §"Preconditions" items 2 and 3.
