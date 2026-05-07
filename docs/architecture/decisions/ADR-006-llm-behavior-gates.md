# ADR-006 — LLM Behavior Gates

Status: Accepted (via this PR)

## Context

Phase 14a는 `plan-review-deep.md` Section 1에 **F1 4 subfacet** (Reproducible Failure / Staged Gate / Immutable Verification / Full-Solution Verification)을 박제하고 `validate.sh`로 staged gate를 강제한다. 이는 **실행/검증 계약** — 코드가 실제 어떻게 검증되는가에 대한 단일 소스 오브 트루스.

Phase F는 mattpocock/skills `tdd`와 garrytan/gstack `office-hours-ddd-discovery`를 vendoring해서 TDD discipline + DDD discovery 도구를 박제했다.

남은 갭: **PR-level 입력 계약** — LLM 에이전트가 PR을 만들 때 무엇을 명시해야 하고 (Goal, Assumptions, Scope) 무엇을 하지 말아야 하는가 (요청 외 변경, 가짜 추상화). Karpathy의 4 원칙 (forrestchang/andrej-karpathy-skills, MIT)은 이 영역을 다루지만 본 템플릿에 박제되지 않은 상태.

자동화된 PR 생성·리뷰 workflow에서 이 입력 계약이 빠지면 다음 회색지대가 열린다:
- "make it work" 같은 모호한 목표가 코드 작성으로 이어짐
- 조용히 가정하고 진행 (가정 미공개)
- 인접 코드 "있는 김에" 개선 (변경 범위 폭증)
- 단일 사용처 추상화 / 가짜 유연성 (코드량 증가)

## Decision

**4-Gate Behavior Contract**를 채택. `.claude/rules/llm-behavior-gates.md`에 박제.

| # | Gate | 출처 | F1 관계 |
|---|------|------|--------|
| 1 | Goal Defined | Karpathy §4 (Goal-Driven Execution) | F1.d entry condition |
| 2 | Assumption Surfaced | Karpathy §1 (Think Before Coding) | 무관 — 신규 영역 |
| 3 | Surgical Diff | Karpathy §3 (Surgical Changes) | 무관 — 신규 영역 |
| 4 | Minimum Code | Karpathy §2 (Simplicity First) | 무관 — 신규 영역 |

**역할 분리 1줄**:
- Behavior Gates = Upstream LLM 행동 계약 (PR-level 입력)
- F1.a-d = Downstream 실행/검증 계약 (`plan-review-deep.md` §1)

테스트 우선·CI green·재현 가능성·E2E coverage 등 실행 결과 측 위반은 F1로 위임. **중복 정의 금지**.

자동 강제: `.github/pull_request_template.md`의 SAFE_OP 마커 블록 + `## Done` 섹션 + `.github/workflows/pr-meta-check.yml`의 PR 메타 검사.

## Consequences

### 긍정

- LLM 에이전트가 PR 생성 시 가정·목표·범위를 의무적으로 명시 → 자동화 회색지대 차단
- F1과 명확한 역할 분리 → 중복 정의 / 기준 하향 회피
- Karpathy 4 원칙이 본 템플릿의 명시적 운영 계약으로 승격 → MIT 출처 cross-link
- `pr-meta-check.yml`이 PR 본문 형식만 검사 → `validate.sh`/F1과 충돌 없음
- 외부 포크 PR도 동일 trigger (코멘트 `ACK SCOPE` 경로)

### 부정

- PR template 길이 ~80줄 (기존 60줄 + SAFE_OP 마커 블록 ~20줄) → 작성 부담 증가
- 4 gate를 외워야 함 → 학습 곡선 (단 PR template이 자동 채움)
- 워크플로 검증 실패 시 차단 → 초기 운영 중 false positive 가능성 (단 마커 기반 → 정규식 대비 견고)
- F1과 본 rule 사이 cross-drift 발생 가능 → cross-link 명시로 완화하나 V_drift 유사 CI guard 추가 검토 필요 (Phase G 후보)

## Alternatives

### A. Karpathy 6 gate 모델 (원안)

6 gate (Goal / Assumption / Test First / Surgical / Minimum / CI Green) 박제. **기각**.
- Test First와 CI Green이 F1.a / F1.b/c/d와 정면 중복
- "CI green"이 F1 엄격 기준의 하향 해석 탈출구가 됨
- 4라운드 codex grill 후 발견된 본질 문제

### B. `docs/SAFE_OPERATION.md` 단독 박제

문서로만 박제. **기각**.
- LLM이 실제 따르는 건 docs보다 `.claude/rules/`. 우선순위 밀림
- PR 자동화 입력 계약이 docs에 박제되면 강제력 약함

### C. Phase G discuss로 미루기

Tier-2 11 unique 옆에 추가 후보로 두기. **기각**.
- 운영 계약은 지금 고정해야 함. 후보로 두면 다시 흔들림
- Phase G는 별도 Pocock 4 추가 skill + ST×6Q + 14a-bis Revision 등 다른 후보 우선

### D. ADR 단독 (rule 없이)

결정만 ADR로 박제하고 실행 rule은 만들지 않음. **기각**.
- ADR은 결정 기록. 실행 가능한 강제 매커니즘 없음
- LLM이 PR 작성 시 참조할 단일 source 필요 → rule 형태가 적합

## Status

Accepted via this PR.

향후 변경:
- 6→4 축소를 다시 6으로 되돌리려면 본 ADR을 superseded 처리 + 새 ADR 발행
- F1과 본 rule 사이 keyword cross-drift 검출이 필요해지면 V_drift 유사 CI guard 추가 (별도 ADR)
- 외부 사용자 increase 시 plugin marketplace 분리 검토 (별도 Comparisons + ADR)

## References

- [forrestchang/andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills) (MIT) — Karpathy 4 원칙 원본
- [`.claude/rules/plan-review-deep.md`](../../../.claude/rules/plan-review-deep.md) §1 — F1.a-d 4 subfacet
- [`.claude/rules/llm-behavior-gates.md`](../../../.claude/rules/llm-behavior-gates.md) — 본 rule 본문
- `Comparisons/LLM Skill Distribution Inline vs External Comparison` (Obsidian wiki) — codex 포기비용 분석 (4라운드)
- `Reference/Karpathy LLM Coding Guidelines Reference` (Obsidian wiki) — 원본 distillation
