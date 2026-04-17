# Spike Test YYYY-MM-DD — <what you measured>

> **Copy this file.** Rename to `spike-test-YYYY-MM-DD-<slug>.md`.
> Pattern abstracted from `checkmate-smu/checkmate-web/docs/ppt/spike-test-0411/RESULTS.md`.

---

- **Purpose**: one sentence — what question does this test answer?
- **Method**: tool (k6, Locust, Artillery), dataset size, threshold
- **Outcome**: one sentence — the headline result
- **Date**: YYYY-MM-DD
- **Test script**: link to `tests/load/...` or `scripts/k6/...`
- **Raw data**: link to `.json` / `.csv` output

## Headline numbers

Put the one or two numbers that matter at the top. No tables with
more than three rows — if it doesn't fit, it isn't the headline.

| Scenario | Metric | Threshold | Observed |
|---|---|---|---|
| **Scenario A** | p95 latency | < 500 ms | **XXX ms** |
| **Scenario A** | error rate | < 1% | **X.X%** |

> **Primary finding**: one sentence the reader remembers.

## Separate problems found

If the test surfaced multiple distinct issues, name each one. A single
test often reveals a data problem **and** an algorithm problem — don't
conflate them.

### Problem 1 — <name>

- **Root cause**:
- **Impact**:
- **Example**: a concrete query/input that triggers it

### Problem 2 — <name>

...

## Breakdown

Optional — a more detailed table per scenario or per category. Include
only if it adds information beyond the headline.

| Category | N tested | N matched | Match rate |
|---|---|---|---|
| ... | ... | ... | ... |

## Latency / throughput reference

- Average: X ms
- p95: X ms
- p99: X ms
- Max: X ms
- Throughput: X req/s

## Mitigation strategy

One row per distinct problem. Each row explains what the team will
change and by when.

| Problem | Strategy | Target (sprint / date) |
|---|---|---|
| ... | ... | ... |

## Honest framing for the audience

The oral answer you'd give if someone asked, "so what?" One paragraph.
Do not oversell; acknowledge limits openly.

> "We measured the limit, designed around it, and have a clear
> improvement path. The 3-tier cascade is validated — Tier 1 coverage
> is a data problem we can address with adapter pattern, not a design
> flaw."

## Conclusions

Numbered takeaways, each under one sentence.

1. ...
2. ...
3. ...

## Downstream artifacts referencing this result

Where does this result get cited afterward?

- ADR-NNN: <decision this test informs>
- RTM row update for NFR-XX: <new measurement>
- Slide deck: `docs/briefings/YYYY-MM-DD-<event>/` (if Briefings
  module is installed)
