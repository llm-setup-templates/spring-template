# Briefings (opt-in module)

Dated, frozen archives of meetings, interviews, and presentations.
Once the event has happened, the folder is **immutable** — new
material goes into a follow-up dated folder, not into the old one.

Pattern abstracted from `checkmate-smu/checkmate-web/docs/interviews/`
where each professor interview has its own dated folder containing
slide outline, talking points, decision checklist, and archived
slides.

## Folder convention

```
docs/briefings/
├── README.md                          ← this file
├── _template/                         ← copy this; rename to a dated folder
│   ├── CLAUDE.md                      ← agent context for this briefing
│   ├── README.md                      ← one-line index for humans
│   ├── slide-outline.md               ← storyboard + style pick
│   ├── talking-points.md              ← spoken delivery notes
│   ├── decisions-checklist.md         ← what this briefing must conclude
│   ├── open-questions.md              ← unresolved items going in
│   └── slides/                        ← rendered slides (.html / .pdf / .pptx)
└── YYYY-MM-DD-<slug>/                 ← each real briefing folder
    └── ... same 7 files ...
```

## Naming

`YYYY-MM-DD-<slug>/` where `<slug>` is kebab-case and names the event:

- `2026-04-14-professor-interview/`
- `2026-05-02-sprint-2-review/`
- `2026-06-10-stakeholder-demo/`

The date is when the briefing **happens**, not when the folder is
created.

## Frozen after delivery

After the event, the folder enters a **frozen** state:

- No editing existing files (except typo / broken-link fixes)
- Follow-ups, corrections, or next-step material go into a new
  folder: `YYYY-MM-DD-<slug>-followup/` or
  `YYYY-MM-DD-<slug>-nextsteps/`
- This preserves "what did we actually say on that date" as an
  audit trail

## What goes in a briefing folder

| File | Audience | When written |
|---|---|---|
| `CLAUDE.md` | LLM agent | Before: context / tone / constraints for the briefing |
| `README.md` | Humans | Before: summary + file index |
| `slide-outline.md` | Author | Before: storyboard + style shortlist |
| `talking-points.md` | Presenter | Before: spoken delivery notes |
| `decisions-checklist.md` | Attendees | Before: what must be concluded |
| `open-questions.md` | Attendees | Before: unresolved items |
| `slides/*.html` or `.pdf` | Audience | Before: final rendered output |

`decisions-checklist.md` and `open-questions.md` are the items the
briefing is **meant to resolve** — they're used during the event
itself, so no "write up afterwards" rule applies to them.

## What does NOT go in a briefing folder

- **Post-mortems of the event itself** — those go in `docs/reports/`
  as a PAAR
- **ADRs decided at the event** — those go in
  `docs/architecture/decisions/`. The briefing folder can link to
  them, but it does not hold them
- **Ongoing collaboration material** — Notion, Slack threads, and
  ephemera live elsewhere. Briefings archive the **moment** of the
  event

## Relationship to Reports

Briefings and Reports can reference each other freely:

- A briefing's `slide-outline.md` often cites a report as evidence
  (e.g. "Spike-test from 2026-04-11 shows...")
- A report's "downstream artifacts" section links the briefings
  where the report was presented
