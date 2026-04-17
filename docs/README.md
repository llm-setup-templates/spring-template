# Documentation

> Replace this line with your project name and one-sentence description.

This tree is installed by Phase 5.5 of the `llm-setup-templates/typescript-template`
setup. It follows a four-module layout: `Core` is always present;
`Reports`, `Briefings`, and `Extended` are opt-in and may have been
trimmed from this copy.

## Where do I put this document?

```
New document → Which type?

├─ A final technical decision (becomes the code)
│   → architecture/decisions/ADR-NNN-<slug>.md  (Accepted, append-only)
│
├─ A proposal still in debate / needs peer review
│   → architecture/decisions/RFC-NNN-<slug>.md  (Proposed, Draft PR)
│
├─ One feature's I/O, preconditions, logic
│   → requirements/FR-XX-<slug>.md               (copy _FR-template.md)
│   → also add a row to requirements/RTM.md
│
├─ A measurement / comparison / spike / API deep-dive
│   → reports/{spike-test|benchmark|api-analysis}-YYYY-MM-DD-<slug>.md
│
├─ A post-mortem / deep troubleshooting write-up
│   → reports/paar-YYYY-MM-DD-<slug>.md
│
├─ Materials for a specific meeting / talk
│   → briefings/YYYY-MM-DD-<slug>/  (copy briefings/_template/)
│
└─ Architecture big picture
    → architecture/overview.md      (C4 Lv1 — Core)
    → architecture/containers.md    (C4 Lv2 — Extended)
    → architecture/DFD.md           (Data Flow Diagram — Extended)
```

## Tree

```
docs/
├── README.md                          ← you are here
├── requirements/
│   ├── RTM.md                         ← single source of truth for FR → code → test
│   └── _FR-template.md
├── architecture/
│   ├── overview.md                    ← C4 Lv1 (System Context)
│   ├── containers.md                  ← C4 Lv2 (opt-in: Extended)
│   ├── DFD.md                         ← Data Flow Diagram (opt-in: Extended)
│   └── decisions/
│       ├── README.md                  ← ADR/RFC workflow
│       ├── _ADR-template.md
│       └── _RFC-template.md
├── reports/                           ← opt-in: Reports
│   ├── README.md
│   ├── _spike-test-template.md
│   ├── _benchmark-template.md
│   ├── _api-analysis-template.md
│   └── _paar-template.md
├── briefings/                         ← opt-in: Briefings
│   ├── README.md
│   └── _template/
└── data/                              ← opt-in: Extended
    └── dictionary.md
```

## Rules that apply everywhere

- **Filenames ending in `_template.md` are NOT edited in place.** Copy
  them first (removing the leading `_`), then edit the copy
- **ADRs are append-only.** Never edit an Accepted ADR to change the
  decision — write a new ADR and mark the old one `Superseded by
  ADR-NNN`. See `architecture/decisions/README.md`
- **RTM is updated in the same PR as the code** that implements or
  changes an FR
- **`.claude/rules/documentation.md` is the source of truth** for the
  naming conventions and ADR lifecycle. If this README drifts from
  that file, trust the rules file

## Removing modules you don't use

If you're not using a module, remove its tree:

```bash
rm -rf docs/reports/      # if not publishing measurement reports
rm -rf docs/briefings/    # if no recurring meetings / talks
rm -f  docs/architecture/containers.md docs/architecture/DFD.md
rm -rf docs/data/         # last two together: no C4 Lv2, no DD
```

Then edit this file to remove the corresponding rows from the tree
diagram and the decision tree above.
