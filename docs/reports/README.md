# Reports (opt-in module)

Portfolio-grade write-ups of measurements, comparisons, and incidents.
These are the documents you would **show a professor, a hiring panel,
or an external stakeholder** to demonstrate rigor. Each template is
built around an explicit **"honest framing for the audience"** section
— the oral answer you'd give if someone asked, "so what?"

## Which template do I pick?

| If you're writing about… | Use this template | Output file |
|---|---|---|
| A load / burst / spike test (k6, Locust, Artillery) | `_spike-test-template.md` | `spike-test-YYYY-MM-DD-<slug>.md` |
| Framework / library comparison with a clear "chose X" at the end | `_benchmark-template.md` | `benchmark-YYYY-MM-DD-<slug>.md` |
| Deep dive into an external API / core system — how it works, where it breaks, how to work around it | `_api-analysis-template.md` | `api-analysis-YYYY-MM-DD-<slug>.md` |
| Post-mortem or deep troubleshooting write-up | `_paar-template.md` | `paar-YYYY-MM-DD-<slug>.md` |

## Naming

- All reports are dated: `<type>-YYYY-MM-DD-<slug>.md`
- The date is when the work was done, not when the document was
  written up
- Slug is kebab-case, short, searchable: `fc-api-korean-coverage`,
  `spring-boot-vs-quarkus-throughput`

## Reports and ADRs

A benchmark often produces a decision. The pattern:

1. Write the benchmark report with the numbers
2. Link the report from a new ADR that states the chosen framework
3. Both documents live on. The benchmark has the evidence; the ADR
   has the conclusion

The benchmark is the paper trail the ADR references — not a substitute
for the ADR.

## Reports and PAAR

PAAR (Problem / Action / Analyze / Result) is the post-mortem format.
Use it for:

- Production incidents
- Test / CI flake investigations
- Performance regressions that took hours to diagnose
- Any situation where "what happened and how do we prevent it" is the
  artifact worth preserving

It's the one report type that's reactive, not proactive. The other
three (spike / benchmark / api-analysis) are planned work.
