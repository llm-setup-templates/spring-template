# Local addendum — Architecture rule enforcement timing

대부분 DDD architecture rule (ArchUnit, Spring Modulith `ApplicationModules.verify()`, ByteBuddy)은 **test phase build-time** (`gradle test` / `vitest run` / `pytest`) 검증입니다. javac/tsc/mypy compile-time이 아닙니다. 단일 예외는 `jmolecules-apt` (annotation processor — 진정 compile-time).

SKILL.md가 'verify architecture'라고 할 때, 이 템플릿 맥락에서는 **test-phase 검증**으로 해석하세요.

## 적용 가이드

| Stack | Architecture rule 도구 | 검증 시점 |
|---|---|---|
| Spring (Java) | ArchUnit, Spring Modulith `verify()` | test phase (`./gradlew test`) |
| Spring (Java) | jmolecules-apt | **compile time** (annotation processor — 단일 예외) |
| TypeScript | dep-cruiser (`npm run dep-check`), Vitest browser mode | test phase / pre-commit |
| Python | import-linter (`uv run lint-imports`), pytest | test phase / pre-commit |

> Source: Phase D 5 정정 freeze (C13 — 2026-04-30)
> Phase F vendor: full Pocock SKILL.md 본문은 generic. Stack별 시점 차이는 본 addendum에서 보정.
