# Benchmark YYYY-MM-DD — <what you compared>

> **Copy this file.** Rename to `benchmark-YYYY-MM-DD-<slug>.md`.
> This report is read alongside the ADR it informs — the benchmark has
> the numbers, the ADR has the decision.

---

- **Purpose**: one sentence — what are we choosing between?
- **Candidates**: A vs B vs C
- **Outcome**: one sentence — which candidate won and why
- **Date**: YYYY-MM-DD
- **Decision ADR**: ADR-NNN-<slug>.md (filled in once the ADR is written)
- **Artifact folder**: link to scripts, configs, raw data

## Hypothesis

Before measuring, write down what you expect to find. If the result
disagrees with the hypothesis, that's a finding — record it.

> Example: "We expect Spring Boot 3.x to outperform Quarkus 3.x on
> cold-start latency by at most 20% given our use case's JVM warmup
> characteristics."

## Candidates

| Candidate | Version | One-line characterization |
|---|---|---|
| A | ... | ... |
| B | ... | ... |
| C (status quo) | ... | ... |

## Evaluation criteria

Weight each criterion — not all matter equally. If you don't know the
weights, the benchmark isn't actionable.

| Criterion | Weight (1–5) | How measured |
|---|---|---|
| Performance (p95 latency) | 5 | k6 run at 100 VU for 10 min |
| Developer ergonomics | 4 | Hours to implement the reference FR |
| Ecosystem maturity | 3 | Library count + GitHub stars + last-release date |
| Learning curve | 2 | Team survey after 1-week spike |

## Method

- **Environment**: hardware, container resources, JVM / Node version,
  network conditions
- **Workload**: what request shape, body size, concurrency, duration
- **Metrics collected**: p50 / p95 / p99 latency, throughput, error
  rate, CPU %, memory, cold-start time
- **Repetitions**: N runs, results averaged; discard first warmup run

## Results

### Headline table

| Criterion | A | B | C |
|---|---|---|---|
| p95 latency | X ms | Y ms | Z ms |
| Implementation time | N weeks | N weeks | N weeks |
| Ecosystem score | ... | ... | ... |
| **Weighted total** | **XX** | **YY** | **ZZ** |

### Chart

Embed or link chart images. Chart files live next to the benchmark
report (`.png`, `.svg`) or link to a live version (`.html` with
Plotly/Chart.js).

![Latency comparison](chart-<slug>.png)

## Interpretation

One paragraph per candidate. Not "A was fastest" — explain **why** A
was fastest given the evaluation criteria.

## Decision

One sentence. This sentence is repeated verbatim in the ADR that
follows.

> "Adopt Candidate B. The 15% latency penalty is offset by a 50%
> reduction in implementation time, and the team's existing familiarity
> with the ecosystem de-risks the rollout."

## Caveats

What would **change** this decision?

- If traffic grows 10×, revisit — the latency gap becomes material
- If a team member with B experience leaves, the ergonomic advantage
  shrinks
- If library X ships a breaking change in its 2.0, the ecosystem score
  for B drops

## Appendix

- Raw JSON / CSV results: `docs/reports/data/benchmark-YYYY-MM-DD/`
- Reproduction: `npm run benchmark:<slug>` (if scripted) or manual steps
- Prior art: links to third-party benchmarks of the same candidates,
  with a note on where ours agrees or diverges
