# ADR-005: Skill Vendor Policy

> Status: Accepted
> Date: 2026-05-06
> Phase: F (template DDD/TDD augmentation)
> Related: ADR-001, ADR-002, ADR-003, ADR-004 (repo-scoped only)

## Context

3 templates (spring/typescript/python)에 외부 skill (Pocock tdd / Garry Tan office-hours)을
박제할 때 vendor 정책 필요. Round 1 plan-review-deep CX-1 Critical에서
"frontmatter 추가 = byte-identical 위반" 지적되어 정책 명문화.

## Decisions

### D-1: SKILL.md 박제 정책 (이중 트랙)

**A.1 — Pocock `tdd` skill = full directory verbatim**:
- 6 files (SKILL.md + 5 *.md) 그대로 복사. frontmatter 수정 0건. 본문 수정 0건.
- 메타 (license/upstream/sync)는 sibling `UPSTREAM.md`로 분리.
- Local addendum (Phase D 정정)은 별도 `_local-addendum.md`.

**A.2 — gstack `office-hours` = adapted skill (verbatim 불가)**:
- Standalone vendor 불가 — `gbrain` schema, `~/.gstack/builder-profile.jsonl`, `~/.gstack/projects/{repo_slug}/*-design-*.md`, `~/.gstack/analytics/eureka.jsonl` 의존
- `/plan-ceo-review`, `/plan-eng-review` cross-skill 의존
- SKILL.md.tmpl 자동 생성 (gen:skill-docs script) build infra
- 6 forcing questions 본문(MIT 표기 verbatim) + DDD discovery 맥락 = adapted skill.
- frontmatter = Pocock 정합 (`name`, `description`) + `allowed-tools` 3개만 추가.

거부된 대안:
- (B) frontmatter override — verbatim 위반
- (C) ecosystem stub — gstack 의존성 재현 비용 과다

### D-2: Reference 가이드 _template 위치

`docs/guides/_template.md` (root, 3 templates byte-identical).

거부된 대안: archetype 내부 / `.claude/templates/`.
근거: cross-cutting reference + 3 templates 일관성.

### D-3: 6Q × DDD 매핑 doc 위치

`docs/patterns/ddd-discovery-via-6q.md` (root, spring/ts; python deferred — archetype 없음).

거부된 대안: `docs/guides/` / archetype 내부.
근거: spring 이미 root `docs/patterns/` 존재 (sibling to ddd-tdd-cross-stack.md).

## Consequences

- ✅ Verbatim vendor 시 frontmatter 위반 차단 (CX-1 fix)
- ✅ License 의무 충족 (UPSTREAM.md MIT 전문 inline, LICENSES.md 신설 X)
- ✅ Sync trigger 14a-bis Revision 2026-11-01에 SHA 비교 자동화 가능
- ⚠️ Adapted skill의 fair use 범위는 MIT verbatim quote + attribution 의무 — UPSTREAM.md inline로 충족

## References

- Phase F PLAN.md §2 (D-1/D-2/D-3 표)
- Wave 0 PIN.md sha256 hashes
- mattpocock/skills (KWONSEOK02 fork) MIT, garrytan/gstack MIT
