# Briefing context — <event name>

> Context file for the LLM agent when working inside this briefing
> folder. Before generating slides / talking points / outlines, read
> this file first.

## Event

- **Date**: YYYY-MM-DD
- **Type**: professor interview / sprint review / stakeholder demo / conference talk
- **Audience**: who is in the room? What do they know? What do they NOT know?
- **Audience count**: N people
- **Duration**: N minutes presentation + N minutes Q&A
- **Language**: Korean / English / mixed
- **Tone / mood**: formal / conversational / celebratory / cautious

## Goals (ranked, most → least important)

1. <Primary goal — if we only accomplish one thing, this is it>
2. <Secondary goal>
3. <Tertiary goal>

## What to emphasize

- Concrete measurements over claims ("Korean FC API: 0/50 match,
  10% return rate")
- Honest limits over marketing ("3-Tier Cascade handles no-match
  gracefully — no fabricated scores")
- One decision per slide — multiple decisions crammed together
  dilute attention

## What to avoid

- Jargon the audience doesn't share (check with team if unsure)
- Screenshots of code unless the audience is engineering
- More than 3 bullets per slide
- Placeholder text in rendered slides ("Lorem ipsum", "TODO")

## Source material

- Reports to draw from: `docs/reports/<file>.md`
- ADRs referenced: `docs/architecture/decisions/ADR-NNN`
- FRs featured: `docs/requirements/FR-XX`

## Prior briefings to learn from

Links to previous briefings in this line (if any). What worked?
What did the audience push back on?

- `docs/briefings/YYYY-MM-DD-<slug>/` — <one-line takeaway>
