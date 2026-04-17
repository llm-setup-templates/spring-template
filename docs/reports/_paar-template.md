# PAAR YYYY-MM-DD — <one-line incident description>

> **Copy this file.** Rename to `paar-YYYY-MM-DD-<slug>.md`.
> PAAR = Problem / Action / Analyze / Result. Use for post-mortems,
> deep troubleshooting write-ups, and any situation where "what
> happened and how do we prevent it" is the artifact worth keeping.

---

- **Date**: YYYY-MM-DD (when the incident / investigation occurred)
- **Author**: @github-handle
- **Severity**: S1 / S2 / S3 / S4
- **Systems affected**: ...
- **Users affected**: count or percentage
- **Total time-to-detection**: N minutes
- **Total time-to-resolution**: N hours
- **Status**: in-progress / resolved / monitoring

## Problem

Define the situation objectively. Numbers over adjectives.

- **What we observed**: ...
- **User impact**: quantified — N failed requests, N sessions lost,
  etc.
- **Timeline**:
  - `HH:MM` — first symptom (monitoring alert / user report)
  - `HH:MM` — incident declared
  - `HH:MM` — mitigation applied
  - `HH:MM` — fully resolved
- **Initial hypotheses**: what did we guess first, even if wrong?

## Action

What the responders did, in chronological order. Include the dead ends
— they're often more informative than the eventual fix.

1. `HH:MM` — Check dashboard X, confirmed spike in metric Y
2. `HH:MM` — Hypothesis: database connection pool exhaustion. Checked
   pool metrics — ruled out (pool was at 40% utilization)
3. `HH:MM` — Hypothesis: upstream provider outage. Checked
   provider status page — confirmed degraded service on their side
4. `HH:MM` — Mitigation: enabled circuit breaker fallback,
   requests now returning cached responses
5. `HH:MM` — Provider recovered; cleared circuit breaker; verified
   metrics returned to baseline

## Analyze

Root-cause analysis. Go past the first-order cause — each "why"
unlocks a deeper layer. Five Whys is a useful scaffold.

### Immediate cause

Upstream provider returned 5xx for N minutes.

### Contributing factors

- Our timeout for the upstream was 30 seconds — long enough to
  exhaust our thread pool
- We had no circuit breaker configured on this integration
- Our monitoring alerted on our own 5xx rate, not on upstream 5xx,
  so detection lagged the incident by N minutes

### Root cause (the one we can fix structurally)

When this integration was added (ADR-NNN), resilience patterns were
left as "future work" that was never scheduled. The absence was
invisible until an upstream outage exposed it.

### Contributing human factors

- Runbook for this integration didn't exist — responders were
  reconstructing the architecture during the incident
- On-call handoff 15 minutes before the alert meant the receiving
  on-call lacked context

## Result

What changed as a consequence? Every PAAR should produce **at least
one permanent artifact** — a code change, a runbook, an alert, a
configuration. "We'll be more careful" is not a result.

### Immediate fixes (shipped during / right after the incident)

- [x] Circuit breaker enabled for integration X
      — PR #NNN
- [x] Alert added for upstream 5xx rate
      — PR #NNN

### Follow-up (planned)

- [ ] ADR-NNN: adopt standard resilience patterns for all external
      integrations
- [ ] Runbook: `docs/briefings/runbooks/integration-X.md` (if
      Briefings module is installed) or `docs/reports/runbook-X.md`
- [ ] Retroactively review the other N integrations for the same gap

### Metrics to watch

- Upstream 5xx rate alert fires before our user-facing error rate
  does — verify on the next incident
- Circuit breaker trip count / week — baseline and alert threshold

## Prevention

What would have prevented this entirely? Name the process or tool,
not the behavior.

- A resilience-pattern checklist added to the
  `.github/ISSUE_TEMPLATE/adr.yml` template — every integration ADR
  now has to explicitly answer "what is the circuit breaker strategy"
- A pre-merge check in CI that fails when `axios` / `fetch` appears
  without an accompanying retry/timeout config

## References

- Incident channel log: link
- Dashboard snapshots: link (frozen images, not live dashboards —
  they'll scroll out of range)
- Related ADRs / PRs
