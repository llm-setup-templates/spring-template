# Java / Spring Boot Template — LLM Agent Setup Prompt

> This document instructs an autonomous coding agent (Claude Code / Cursor)
> to scaffold a new Spring Boot 3 project from an empty directory to a green
> CI pipeline on GitHub.

## 1. Preface — LLM Agent Meta-Instructions

You are an autonomous coding agent. Execute this document Phase by Phase
from top to bottom.

### Execution Rules
- Use the Bash tool for shell commands. Use the Write tool for config files.
- Each Phase is **fail-fast**. On failure, consult the Troubleshooting
  section and retry up to **3 times** before escalating to the human.
- Never skip the **Local Verify** phase. Do not claim completion until CI
  shows green on the first push (use `gh run watch`).
- Use **pinned versions** from the Config Reference Appendix. Do not guess.
- Do not ask the human for input during execution except for:
  (a) GitHub repo name
  (b) visibility (private/public)
  (c) final approval before pushing

### Placeholder Index

All `{{...}}` placeholders below must be filled before execution:

| Placeholder | Scope | Example |
|-------------|-------|---------|
| `{{PROJECT_NAME}}` | Phase 0/1 — repo name + artifactId | `my-spring-app` |
| `{{PROJECT_NAME_LOWER}}` | Phase 1 — packageName (no hyphens) | `myspringapp` |
| `{{BASE_PACKAGE}}` | ArchitectureTest.java — scan root | `com.example.myspringapp` |
| `{{TASK_EXECUTION_ROLE_ARN}}` | task-definition.json | `arn:aws:iam::123456789:role/ecsTaskExec` |
| `{{SECRET_ARN_DB_USER}}` | task-definition.json | `arn:aws:secretsmanager:ap-northeast-2:...` |
| `{{SECRET_ARN_DB_PASSWORD}}` | task-definition.json | `arn:aws:secretsmanager:ap-northeast-2:...` |
| `{{AWS_ACCOUNT_ID}}` | task-definition.json | `123456789012` |
| `{{AWS_REGION}}` | task-definition.json | `ap-northeast-2` |
| `{{RDS_ENDPOINT}}` | task-definition.json | `mydb.xxxx.ap-northeast-2.rds.amazonaws.com` |
| `{{DB_NAME}}` | task-definition.json | `appdb` |

### Success Criteria
- [ ] GitHub repository created and first commit pushed
- [ ] All CI jobs pass on the first push
- [ ] CodeRabbit app connected (or fallback configured)
- [ ] Local `./gradlew checkFormat checkstyleMain checkstyleTest spotbugsMain test build` passes from a fresh clone

---

## 2. Prerequisites
- `gh` CLI authenticated (`gh auth status`)
- `git` ≥ 2.40
- JDK ≥ 21 (Temurin recommended)
- `curl`, `unzip` available
- Docker Desktop running (for Testcontainers + local DB)

---

## 3. Phase 0 — Repo Init

```bash
gh auth status || exit 1
# JDK check is advisory only: settings.gradle.kts uses the
# foojay-resolver-convention plugin, so Gradle will auto-download JDK 17
# to ~/.gradle/jdks/ on first build regardless of the host JDK version.
# The warning below is a soft hint for faster first-run experience.
java -version 2>&1 | grep -qE '"17\.' || {
  echo "INFO: Host JDK is not 17. Gradle will auto-provision JDK 17 on first build."
  echo "To speed up first build: sdk install java 17.0.13-tem   # or brew install temurin@17"
}
mkdir {{PROJECT_NAME}} && cd {{PROJECT_NAME}}
git init -b main
gh repo create {{PROJECT_NAME}} --private --source=. --remote=origin
```

---

## 4. Phase 1 — Spring Initializr Scaffolding

```bash
curl -G https://start.spring.io/starter.zip \
  -d type=gradle-project-kotlin \
  -d language=java \
  -d bootVersion=3.5.0 \
  -d javaVersion=21 \
  -d groupId=com.example \
  -d artifactId={{PROJECT_NAME}} \
  -d packageName=com.example.{{PROJECT_NAME_LOWER}} \
  -d dependencies=web,data-jpa,validation,actuator \
  -o starter.zip
unzip starter.zip
rm starter.zip
chmod +x gradlew

# Record the exec bit in git so Linux CI runners can run ./gradlew.
# Without this, CI fails with "./gradlew: Permission denied" (exit 126).
git update-index --chmod=+x gradlew
```

> **Spring Boot version note**: `start.spring.io` enforces a rolling
> compatibility window. As of 2026-04-14 the minimum accepted is 3.5.0
> (earlier versions return HTTP 400 `Invalid Spring Boot version,
> compatibility range is >=3.5.0`). Check the current minimum with:
> `curl -s https://start.spring.io/metadata/client | jq -r '.bootVersion.default'`

---

## 5. Phase 2 — DevDeps (build.gradle.kts 수정)

Copy `examples/build.gradle.kts` from this template and merge into your generated `build.gradle.kts`.

Key additions to the generated file:

**plugins block — add after spring boot plugin:**
```kotlin
id("checkstyle")
id("com.github.spotbugs") version "6.0.26"
id("io.spring.javaformat") version "0.0.43"
```

**dependencies block — add these:**
```kotlin
implementation("org.springdoc:springdoc-openapi-starter-webmvc-ui:2.5.0")
runtimeOnly("org.postgresql:postgresql")
testRuntimeOnly("com.h2database:h2")
testImplementation("com.tngtech.archunit:archunit-junit5:1.3.0")
testImplementation("org.springframework.boot:spring-boot-testcontainers")
testImplementation("org.testcontainers:junit-jupiter")
testImplementation("org.testcontainers:postgresql")
testRuntimeOnly("org.junit.platform:junit-platform-launcher")
```

**Checkstyle + SpotBugs config blocks (append to build.gradle.kts):**
```kotlin
checkstyle {
    toolVersion = "10.17.0"
    configFile = file("checkstyle/checkstyle.xml")
    isIgnoreFailures = false
}

spotbugs {
    excludeFilter.set(file("spotbugs/spotbugs-exclude.xml"))
    ignoreFailures.set(false)
    toolVersion.set("4.8.6")
}

tasks.withType<com.github.spotbugs.snom.SpotBugsTask> {
    reports.create("html") { enabled = true }
    reports.create("xml") { enabled = false }
}
```

---

## 6. Phase 3 — Config Files

Copy the following files from `examples/` into your project root:

- `examples/checkstyle/checkstyle.xml` → `checkstyle/checkstyle.xml`
- `examples/checkstyle/suppressions.xml` → `checkstyle/suppressions.xml`
- `examples/spotbugs/spotbugs-exclude.xml` → `spotbugs/spotbugs-exclude.xml`
- `examples/archunit/ArchitectureTest.java` → `src/test/java/com/example/{{PROJECT_NAME_LOWER}}/architecture/ArchitectureTest.java`
  - **Replace** `com.example` with `{{BASE_PACKAGE}}` in `@AnalyzeClasses`
  - **Replace** `com.example..` package rules with your base package
- `examples/archunit/archunit.properties` → `src/test/resources/archunit.properties`
  - Required for the day-0 skeleton: ArchUnit 1.4+ fails empty-should rules by default
- `examples/.springjavaformatconfig` → `.springjavaformatconfig`
- `examples/application.yml` → `src/main/resources/application.yml`
- `examples/application-local.yml` → `src/main/resources/application-local.yml`
- `examples/application-test.yml` → `src/test/resources/application.yml`
  - Required: spring init's default `*ApplicationTests.contextLoads` test loads the full Spring context, but the production `application.yml` configures a Postgres datasource that is unavailable on a clean local checkout. The H2 in-memory profile keeps the day-0 verify hands-off.
- `examples/Dockerfile` → `Dockerfile`
- `examples/.dockerignore` → `.dockerignore`
- `examples/docker-compose.yml` → `docker-compose.yml`
- `examples/aws/task-definition.json` → `aws/task-definition.json`
  - Fill all `{{...}}` placeholders with your AWS values
- `examples/config/AppProperties.java` → `src/main/java/com/example/{{PROJECT_NAME_LOWER}}/config/AppProperties.java`
  - Add `@EnableConfigurationProperties(AppProperties.class)` to your main `*Application.java`

---

## 7. Phase 4 — Gradle Tasks

Verify these tasks are available after Phase 2:
```bash
./gradlew tasks | grep -E "checkFormat|applyFormat|checkstyleMain|spotbugsMain|bootJar"
```

Expected output includes: `checkFormat`, `applyFormat`, `checkstyleMain`, `checkstyleTest`, `spotbugsMain`, `bootJar`

---

## 8. Phase 5 — CI Workflow

Copy `examples/ci.yml` → `.github/workflows/ci.yml`

Also copy `examples/.commitlintrc.json` → `.commitlintrc.json`

The CI pipeline runs (in order, fail-fast):
1. `actions/checkout@v4` with `fetch-depth: 0`
2. `wagoid/commitlint-github-action@v6`
3. `actions/setup-java@v4` (Temurin 17)
4. `gradle/actions/setup-gradle@v4`
5. `./gradlew checkFormat`
6. `./gradlew checkstyleMain checkstyleTest`
7. `./gradlew spotbugsMain`
8. `./gradlew compileJava compileTestJava test`
9. `./gradlew build bootJar`

---

## 9. Phase 6 — CodeRabbit Setup

1. Copy `examples/.coderabbit.yaml` → `.coderabbit.yaml`
2. Install CodeRabbit GitHub App: https://github.com/apps/coderabbitai
3. If CodeRabbit trial is unavailable, fall back to the Claude Code Review
   Action (Appendix § Fallback).

---

## 10. Phase 7 — Local Verify (fail-fast)

```bash
./gradlew checkFormat checkstyleMain checkstyleTest spotbugsMain test build bootJar
```

**Docker smoke test (optional — requires Docker running):**
```bash
docker build -t app-local .
docker-compose up -d db
sleep 8
docker-compose ps db | grep -q "healthy" || { echo "DB healthcheck failed"; docker-compose down; exit 1; }
docker-compose down
```

All checks must pass before Phase 8.

---

## 11. Phase 8 — First Push + CI Green

### 11.1 Initial commit (required before Gate 1)

Gate 1 calls `git rev-parse --abbrev-ref HEAD` which requires at least
one commit to exist. On a fresh `git init` repo there is no HEAD yet,
so stage and commit all scaffolded files first:

```bash
git add .
git commit -m "feat(scaffold): initial project setup"
```

### 11.2 Git Safety Gate (MANDATORY — run before push)

```bash
# Gate 1: branch check
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" = "main" ]; then
  echo "BLOCKED: direct commit on main. Moving to feat/initial-setup."
  git branch feat/initial-setup && git checkout feat/initial-setup
fi

# Gate 2: commit message convention
INVALID=$(git log --format=%s -10 | \
  grep -vE '^(feat|fix|docs|chore|refactor|test|ci|build|perf|revert|style)(\([a-z0-9-]+\))?: .+' || true)
if [ -n "$INVALID" ]; then
  echo "BLOCKED: commit message convention violation:"
  echo "$INVALID"
  echo "Fix: git reset --soft HEAD~N and rewrite commits. DO NOT force push."
  exit 1
fi

# Gate 3: uncommitted changes
git diff --quiet && git diff --cached --quiet || {
  echo "BLOCKED: uncommitted changes exist."
  exit 1
}
```

### 11.3 Push + watch CI

CI triggers on `push: [main, dev]` and on `pull_request: [main, dev]`. On a
brand-new repo created via `gh repo create --source=. --remote=origin`, the
remote has no `main` yet. Seed `main` by pushing the feature-branch commit
directly into `main` on first push:

```bash
git push origin $(git rev-parse --abbrev-ref HEAD):main
git push -u origin $(git rev-parse --abbrev-ref HEAD)
gh run watch
```

### 11.4 Success Declaration

Only after `gh run watch` reports all jobs green, you may report the task
as complete to the human.

---

## 12. Troubleshooting

| 증상 | 원인 | 해결 |
|------|------|------|
| `java -version` 17 미인식 | JDK 11/8이 PATH 우선 | Gradle toolchain이 자동 다운로드하므로 그대로 진행 가능. 빠른 첫 빌드를 원하면 `sdk use java 17.x-tem` 또는 JAVA_HOME 재설정 |
| Gradle toolchain 다운로드 실패 (Foojay API 접근 불가) | 방화벽/프록시 차단 | `~/.gradle/gradle.properties`에 프록시 설정 추가 또는 로컬 JDK 17 직접 설치 |
| `./gradlew: Permission denied` (CI 126) | Windows git 이 gradlew 실행 권한 미추적 | `git update-index --chmod=+x gradlew && git commit` — `chmod +x` 만으로는 부족 (Windows 로컬에서 커밋하면 권한 손실) |
| `checkFormat` 가 변경 없이 계속 실패 | spring-java-format 0.0.43 + Gradle 8.14 silent format-vs-check 불일치 | 플러그인을 0.0.47 이상으로 올릴 것 (템플릿은 0.0.47 고정) |
| `checkFormat` 실패, 원인 불명 | Java 파일에 비-ASCII Unicode (box-drawing `──`, em-dash `—` 등) | ASCII 만 사용 — Unicode 주석 제거 |
| Checkstyle `Unable to find .../config/checkstyle/suppressions.xml` | `configDirectory` 미설정 시 Gradle 이 `config/checkstyle/` 기본값 사용 | `checkstyle { configDirectory.set(file("checkstyle")) }` 추가 |
| `FileTabCharacter` 86+ errors | spring-java-format tab 들여쓰기 vs Google Java Style no-tab 충돌 | `suppressions.xml` 에 `<suppress checks="FileTabCharacter" files=".*\.java"/>` 추가 |
| ArchUnit `Rule ... failed to check any classes` | 1.4+ 에서 `archRule.failOnEmptyShould=true` 가 기본 | `src/test/resources/archunit.properties` 에 `archRule.failOnEmptyShould=false` |
| `layeredArchitecture` `Layer 'Controller' is empty` | 빈 scaffold 상태 | `Architectures.layeredArchitecture().withOptionalLayers(true)` |
| `cannot find symbol: interfaces()` | `ArchRuleDefinition.interfaces()` 는 존재하지 않는 메서드 | `classes().that()....and().areInterfaces()` 로 교체 |
| `start.spring.io` HTTP 400 `Invalid Spring Boot version` | 템플릿 고정 버전이 지원 범위 밖 | 최소 3.5.0 사용; `curl -s https://start.spring.io/metadata/client \| jq -r '.bootVersion.default'` 로 현재 기본값 확인 |
| `checkFormat` 실패 (import 순서) | spring-java-format ImportOrder 충돌 | `./gradlew applyFormat`으로 자동 수정 후 재검증 |
| SpotBugs NullPointerException false positive | Spring 의존성 주입 패턴 미인식 | `spotbugs/spotbugs-exclude.xml`에 `NP_NULL_ON_SOME_PATH_FROM_RETURN_VALUE` 추가 |
| Testcontainers `Cannot connect to Dockerd` | CI에서 Docker 미설치 | ci.yml의 ubuntu-latest는 preinstalled Docker 사용 — 로컬에서는 Docker Desktop 기동 확인 |

---

## 13. Essential Checklist

- [ ] `gh auth status` passed
- [ ] JDK 17 available (host install OR Gradle toolchain auto-provision)
- [ ] Spring Initializr command ran in an empty or newly-created directory
- [ ] All config files written (checkstyle, spotbugs, archunit, Dockerfile, etc.)
- [ ] `./gradlew checkFormat checkstyleMain checkstyleTest spotbugsMain test build` passes locally
- [ ] Git Safety Gate passed
- [ ] `gh run watch` shows green CI
- [ ] CodeRabbit app installed or fallback configured

---

## 14. Config Reference Appendix

### § Pinned Versions

| Library | Version | Purpose |
|---------|---------|---------|
| Spring Boot | 3.5.0 | Minimum accepted by start.spring.io as of 2026-04-14 (earlier versions return 400 `Invalid Spring Boot version, compatibility range is >=3.5.0`) |
| Java (Temurin) | 21 | LTS, Spring Boot 3.2+ minimum |
| Gradle wrapper | 8.10+ | build.gradle.kts compatible |
| spring-java-format Gradle plugin | 0.0.47 | `io.spring.javaformat` — 0.0.43 has a silent format-vs-check disagreement under Gradle 8.14 |
| SpotBugs Gradle plugin | 6.0.26 | `com.github.spotbugs` |
| Checkstyle toolVersion | 10.17.0 | `toolVersion` in build.gradle.kts |
| SpotBugs toolVersion | 4.8.6 | `toolVersion` in spotbugs block |
| ArchUnit | 1.4.0 | `com.tngtech.archunit:archunit-junit5` |
| springdoc-openapi | 2.5.0 | `springdoc-openapi-starter-webmvc-ui` |
| Testcontainers BOM | 1.20.x | Managed via Spring Boot BOM |
| wagoid/commitlint-github-action | v6 | CI commitlint step |
| actions/checkout | v4 | CI |
| actions/setup-java | v4 | CI |
| gradle/actions/setup-gradle | v4 | CI Gradle cache |
| postgres (Docker) | 16-alpine | docker-compose |
| eclipse-temurin (Docker) | 17-jdk-alpine / 17-jre-alpine | Dockerfile |

> **Spring Boot version check:** `curl -s https://start.spring.io/actuator/info | jq -r '.bom["spring-boot"].version'`

### § Config File Contents

See `examples/` directory for all ready-to-copy config files:
- `examples/build.gradle.kts` — full Kotlin DSL build file
- `examples/settings.gradle.kts` — single-module settings
- `examples/checkstyle/checkstyle.xml` — Google Java Style base + suppressions
- `examples/checkstyle/suppressions.xml` — spring-java-format conflict suppression
- `examples/spotbugs/spotbugs-exclude.xml` — Spring false positive exclusions
- `examples/archunit/ArchitectureTest.java` — 6-rule ArchUnit test
- `examples/config/AppProperties.java` — @ConfigurationProperties record example
- `examples/.springjavaformatconfig` — spring-java-format activation file
- `examples/application.yml` — production config (open-in-view=false, show-sql=false)
- `examples/application-local.yml` — local docker-compose DB config
- `examples/Dockerfile` — multi-stage JDK17/JRE17 layered jar
- `examples/.dockerignore` — exclude .git, .gradle, build, .claude
- `examples/docker-compose.yml` — Postgres 16 + optional Redis
- `examples/aws/task-definition.json` — ECS Fargate CPU256/Mem512 template

### § CI Reference

See `examples/ci.yml` — step order is critical:
1. `actions/checkout@v4` with `fetch-depth: 0` (FIRST)
2. `wagoid/commitlint-github-action@v6` (AFTER checkout)
3. setup-java, setup-gradle, checkFormat, checkstyle, spotbugs, test, build

### § CodeRabbit Reference

See `examples/.coderabbit.yaml` — 7-item Spring-specific review prompt.
Key: `ignore_formatting: true` — formatting is Checkstyle + spring-java-format's domain.

### § Fallback — Claude Code Review Action

If CodeRabbit is unavailable, add to `.github/workflows/ci.yml`:

```yaml
- name: Claude Code Review (fallback)
  uses: actions/github-script@v7
  if: github.event_name == 'pull_request'
  with:
    script: |
      const body = `@claude Please review this PR for:
      1. ArchUnit violations (check T8 rules)
      2. @Transactional misplacement
      3. JPA N+1 patterns
      4. DTO/Entity leaks`;
      await github.rest.issues.createComment({
        owner: context.repo.owner,
        repo: context.repo.repo,
        issue_number: context.issue.number,
        body
      });
```
