<!--
SAFE_OP 마커 블록과 ## Done 섹션은 자동 검증 대상입니다 (`.github/workflows/pr-meta-check.yml`).
삭제·마커 변경 시 PR 차단. 자세한 4 Behavior Gates: `.agents/rules/llm-behavior-gates.md`.
-->

<!-- SAFE_OP_START -->
Assumptions: [기본값에서 벗어난 가정만, 없으면 "없음"]
Scope: [변경할 파일/디렉토리]
Out-of-scope: [의도적 미변경 영역]
<!-- SAFE_OP_END -->

## Done

표준 Done (다음 3가지 모두 명시):

- [ ] **요구사항 목록** (입력 / 출력 / 에러 / 경계 중 1+ 포함):
- [ ] **산출물 목록** (파일 / 엔드포인트 / CLI 명령):
- [ ] **수용 테스트** (산출물 타입에 맞는 레벨, 자동화 가능):

또는 trivial 작업의 경우 Micro-Done (1줄):

```
요구사항: [한 줄] / 변경: [파일 경로] / 검증: 기존 테스트 통과
```

## Behavior Gates 자체 점검

- [ ] Gate 1 — Goal Defined (Done 정의 위 명시)
- [ ] Gate 2 — Assumption Surfaced (SAFE_OP 마커 블록 위 작성)
- [ ] Gate 3 — Surgical Diff (변경 라인 모두 요청 추적, 명문 예외 외 인접 코드 개선 없음)
- [ ] Gate 4 — Minimum Code (단일 사용처 추상화·요청 외 유연성 없음)

> 실행/검증 (테스트·CI green·재현·E2E)은 F1.a-d (`.agents/rules/plan-review-deep.md` §1)로 위임. 본 점검은 PR-level 입력 계약만.

---

## Summary

<!-- 1–3 sentences. What changes and why. -->

## Related documents

<!-- Link every applicable document. Delete rows that don't apply. -->

- [ ] FR: `docs/requirements/FR-{DOMAIN}-{NNN}.md` — <!-- closes #... -->
- [ ] ADR: `docs/architecture/decisions/ADR-NNN-<slug>.md` — <!-- Accepted via this PR -->
- [ ] RFC: `docs/architecture/decisions/RFC-NNN-<slug>.md` — <!-- still Proposed, not in scope for merge -->
- [ ] Report: `docs/reports/<type>-YYYY-MM-DD-<slug>.md` — <!-- spike / benchmark / api-analysis / paar -->
- [ ] Briefing: `docs/briefings/YYYY-MM-DD-<slug>/` — <!-- event archive -->

## RTM discipline

- [ ] If this PR implements or changes an FR, `docs/requirements/RTM.md`
      is updated in this PR (new row or cell edits) — **mandatory when
      the FR row exists**.

## Architecture / layer checks

<!-- Check everything that applies. Unchecked items with a comment explaining why = acceptable. -->

- [ ] Layer direction respected (`api → domain → repository` via interfaces)
      — no controller → repository shortcut
- [ ] `@Transactional` placed on the service layer (read-only on queries,
      default on writes), never on controllers or repositories
- [ ] Entities (`@Entity`) are NOT returned from `@RestController` — DTOs only
- [ ] No JPA N+1: any `@OneToMany` / `@ManyToOne` fetched eagerly has a
      justification, or `@EntityGraph` / `JOIN FETCH` is used where needed
- [ ] ArchUnit tests pass (`./gradlew test` includes `ArchitectureTest`)
- [ ] Bean Validation annotations on DTO request fields (`@NotNull`,
      `@Email`, `@Size`, etc.) — not post-hoc `if (x == null)` checks
- [ ] No `System.out.println` / `System.err.println` — SLF4J `Logger` only

## Data-flow Balancing Rule (only if DFD changed)

- [ ] No Black Hole (a process with input but no output)
- [ ] No Miracle (a process with output but no input)
- [ ] No Gray Hole (a process whose outputs cannot be derived from its
      inputs — e.g. returns PII that wasn't fetched)
- [ ] Terminology is consistent between parent and child levels

## Verification

- [ ] `./gradlew checkFormat checkstyleMain checkstyleTest spotbugsMain test build bootJar`
      passes locally
- [ ] Tests updated in the same commit as the code change
      (see `.agents/rules/test-modification.md`)
- [ ] If adding / changing a JPA entity, a Testcontainers integration
      test exercises the schema (not only H2 in-memory)

## Business impact (only for large or risky changes)

<!-- Delete this section for routine changes. Required for ADR-level PRs. -->

**Cost**: <!-- infrastructure, managed DB tier, engineer time -->
**Risk**: <!-- what can go wrong, what's the blast radius -->
**Velocity impact**: <!-- what does this enable / block for the next sprint -->
