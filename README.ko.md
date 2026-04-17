# Spring Boot 템플릿 — LLM 에이전트 전용 스캐폴딩

[English README](./README.md)

> Spring Boot 3 + Java 17 (Temurin LTS) + Gradle KTS 기반의 의견이 담긴 템플릿.
> LLM 코딩 에이전트(Claude Code / Cursor)가 빈 디렉토리에서 출발해
> GitHub Actions CI green까지 **중간에 사람 개입 없이** 완주하도록 설계됐습니다.

**실증 검증 완료**: SETUP.md 하나로 Claude Code → CI green, 2분 53초
([증거 run](https://github.com/KWONSEOK02/llm-setup-e2e17-spring/actions/runs/24565850331)).

---

## 왜 이 템플릿이 존재하는가

Spring Boot 프로젝트를 시작하는 방법은 수십 가지입니다. 이 템플릿은 **레이어마다 한 가지 방어 가능한 선택**을 하고, LLM 에이전트가 위에서 아래로 실행하는 SETUP.md를 함께 제공합니다.

**고정된 기술 선택** (이유 포함):

| 레이어 | 선택 | 이유 (기각된 대안) |
|---|---|---|
| Java | 17 (Temurin LTS, Foojay 자동 프로비저닝) | 11/21 모두 유효하지만, 17이 현행 LTS 다수파; Foojay 덕분에 호스트 JDK 버전 무관 |
| 빌드 | Gradle Kotlin DSL 8.x | Maven XML은 장황함; Gradle Groovy DSL은 KTS로 수렴 중 |
| 아키텍처 | 싱글턴 시작, 멀티모듈 대비 (team-dodn 패키지 네이밍) | 처음부터 멀티모듈은 과설계; "절대 멀티모듈 안 함"은 스케일 시 함정 |
| 응답 봉투 | `ApiResponse<T>` 래퍼, `CoreException` 계층 | raw 엔티티 반환은 JPA 상태를 클라이언트에 노출; 서비스 레이어의 `ResponseStatusException`은 레이어 분리 위반 |
| 포매터 | spring-java-format 0.0.47 (공백 소유권) | Checkstyle과 Prettier 스타일 포매팅이 충돌하면 낭비 |
| 린터 | Checkstyle 10.17 (Google Java Style 기반) + SpotBugs 4.8.6 | 스타일 하나, 버그 패턴 하나 |
| 경계 테스트 | ArchUnit (레이어 규칙 10개) | 컴파일 타임이 잡지 못하는 반사 기반 검사 |
| CI 커밋 게이트 | wagoid/commitlint-github-action@v6 | JVM 템플릿은 Husky를 이식성 있게 쓸 수 없음 — CI 수준 게이트 |

---

## 이 템플릿이 적합한 사람

**페르소나 1 — 새 Spring Boot 서비스를 시작하는 1인 개발자 또는 소규모 팀**
- 해결: "패키지는 어떻게? 응답 래퍼는? 에러 타입은? 경계 검사는?"
- 해결 안 함: DB 스키마 설계, 외부 API 연동 선택

**페르소나 2 — LLM 보조 개발 (Claude Code, Cursor)**
- 해결: SETUP.md는 실패 즉시 중단(fail-fast), ArchUnit은 레이어 위반 포착, spring-java-format은 스타일 자동 수정 — 에이전트가 구체적인 빨강→초록 피드백을 받음
- 해결 안 함: 비즈니스 로직; 이 템플릿은 구조를 잡아주지 도메인을 만들지 않음

**페르소나 3 — 비체계적인 Spring Boot 관행에서 리뷰 가능한 코드베이스로 전환하는 팀**
- 해결: Checkstyle + SpotBugs + ArchUnit이 CI에서 구체적인 실패를 하나씩 제시
- 해결 안 함: 마이그레이션 자체

**페르소나 4 — 재현 가능한 Spring Boot 수업을 세팅하는 강사**
- 해결: 모든 학생이 동일한 JDK, Gradle, 플러그인, CI를 가짐
- 해결 안 함: 커리큘럼

---

## 이 템플릿이 맞지 않는 사람

- Spring Boot 2.x 또는 Java 11을 써야 함 → 이 템플릿은 3.x + 17을 고정
- Maven을 원함 → build.gradle.kts / settings.gradle.kts를 pom.xml로 재작성 필요
- 웹 레이어 없는 순수 라이브러리가 필요함 → 이 템플릿은 `spring-boot-starter-web` 기반 서비스 지향
- 처음부터 포트 & 어댑터 방식의 Clean Architecture / Hexagonal이 필요함 → 이 템플릿은 레이어드 우선, CA 대비 구조

---

## 빠른 적합 체크

1. **새로 시작하는 Spring Boot 3 서비스 프로젝트인가?** 아니라면 → 포크를 고려.
2. **레이어드 아키텍처를 수용하고, 필요 시 나중에 멀티모듈로 전환할 의향이 있는가?** 아니라면 → 처음부터 멀티모듈 템플릿을 선택.
3. **Gradle KTS(Maven이나 Groovy DSL 아님)가 괜찮은가?** 아니라면 → 빌드 파일 재작성 필요.

셋 다 예 → [SETUP.md](./SETUP.md)로 이동.

---

## 스케일링 경로 — 싱글턴에서 멀티모듈로

이 템플릿은 **단일 Gradle 모듈**로 시작하지만, team-dodn의 패키지 네이밍 관례를 사용하므로 나중에 코드 구조 변경 없이 Gradle 서브모듈로 분리할 수 있습니다.

**"언제 멀티모듈로 쪼개야 하나"는 Spring 실무에서 흔한 질문**입니다. 이 템플릿의 답은 명확합니다: 지금 당장은 하지 마세요.

현재 패키지 → 미래 모듈 매핑:

| 현재 패키지 | 미래 Gradle 모듈 | 분리 신호 |
|---|---|---|
| `core.api` | `core:core-api` | `core/` 파일 수 > 40 또는 2개 이상 팀이 소유 |
| `core.domain` | `core:core-api` (domain 서브디렉토리) | core-api와 강결합; 추가 분리는 DDD 도입 시만 |
| `core.enums` | `core:core-enum` | 3개 이상 모듈에서 공유 |
| `storage.db` | `storage:db-core` | 복수의 스토리지 백엔드 등장 |
| `clients.*` | `clients:client-*` | SLO가 다른 외부 API 3개 이상 |
| `support.*` | `support:logging`, `support:monitoring` | 재사용 가능한 유틸리티 jar로 배포해야 할 때 |

**분리 시점 판단 기준** — 너무 일찍 쪼개는 것이 안티패턴입니다. 다음 조건 중 하나를 만족할 때까지 싱글턴 유지:
- 컴파일 시간 > 2분 + 거의 수정되지 않는 서브트리를 식별 가능한 경우
- 두 팀이 단일 모듈 테스트 시간 때문에 서로의 CI를 막는 경우
- 서브셋(예: `core.enums`)을 재사용 라이브러리로 배포해야 하는 경우

분리 후에도 ArchUnit 규칙은 그대로 이전됩니다 — 패키지 경계를 강제하며, `./gradlew :core-api:test`가 분리된 모듈에 동일한 ArchUnit 검사를 수행합니다.

---

## 내부 구성

- 세팅 흐름: [SETUP.md](./SETUP.md)
- AI 에이전트 규칙: [CLAUDE.md](./CLAUDE.md)
- 아키텍처 (레이어 규칙, ArchUnit): [.claude/rules/architecture.md](./.claude/rules/architecture.md)
- 검증 루프 (Gradle 태스크 순서): [.claude/rules/verification-loop.md](./.claude/rules/verification-loop.md)
- 테스트 수정 규칙: [.claude/rules/test-modification.md](./.claude/rules/test-modification.md)
- 바로 복사해서 쓸 수 있는 설정 파일: [examples/](./examples/)

---

## 관련 템플릿

- [python-template](https://github.com/llm-setup-templates/python-template) — Python 3.13 + 3가지 아키타입
- [typescript-template](https://github.com/llm-setup-templates/typescript-template) — Next.js 15 + FSD 5 레이어

---

## 라이선스

Apache-2.0
