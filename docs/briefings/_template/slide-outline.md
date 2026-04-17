# Slide outline — <event>

## Meta

- **Topic**:
- **Audience**:
- **Tone**: <one line, e.g. "sober, honest about limits, data-forward">
- **Slide count**: N (cover + body + close)
- **Aspect ratio**: 16:9 (720 × 405 pt)
- **Language**:
- **Delivery window**: N min presentation + N min Q&A
- **Style**: <pick from the shortlist below>

## Style shortlist

Pick one for this briefing. Defaults below follow the CheckMate
convention — edit per event.

| # | Style ID | Best for | Notes |
|---|---|---|---|
| 1 | `executive-minimal` | Professor interview, formal report | Muted palette, generous whitespace |
| 2 | `swiss-international-style` | Data-heavy measurement report | Grid-strong, chart-friendly |
| 3 | `corporate-blue` | Stakeholder / exec review | Trustworthy, conservative |
| 4 | `editorial-magazine` | Internal team share, brainstorming | High info density |
| 5 | `modern-dark` | External demo / launch | Strong visual impact |

If using the `slides-grab` skill chain: run `slides-grab list-styles`
for the full catalog.

## Storyboard

One row per slide. Do not start Stage 2 (HTML generation) until this
table is approved.

| # | Slide title | One-line message | Visual | Source |
|---|---|---|---|---|
| 1 | Cover | <event name, presenter, date> | logo / subtle mark | — |
| 2 | The question | <why we're here in 1 sentence> | big type | — |
| 3 | What we measured | <headline number + unit> | bar chart | `docs/reports/<spike>.md` |
| 4 | What we found | <problem 1 + problem 2> | 2-column table | `docs/reports/<spike>.md` |
| 5 | Decision | <one sentence from the ADR> | quote block | `docs/architecture/decisions/ADR-NNN.md` |
| 6 | What's next | <sprint N targets> | timeline | `docs/reports/<api-analysis>.md` § Recommended path |
| 7 | Honest limits | <what we can't do yet, framed positively> | callout | `docs/reports/<spike>.md` § Honest framing |
| 8 | Close / Q&A | <one line that lands> | — | — |

## Rules

- **One message per slide**. If a slide wants to say two things, split.
- **No placeholder text** in the rendered output. `Lorem ipsum`,
  `TODO`, `[insert chart]` all fail review.
- **Cite the source** for any number. The Source column above carries
  forward into the slide's footer.
- **Images / charts live in the slides/ subfolder** — never hotlink
  to a live URL that could change or break.
