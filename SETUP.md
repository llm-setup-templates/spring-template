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
| `{{TASK_EXECUTION_ROLE_ARN}}` | task-definition.json | IAM role ARN for ECS task execution (pulls image, writes logs) — e.g. `arn:aws:iam::123456789:role/ecsTaskExec` |
| `{{TASK_ROLE_ARN}}` | task-definition.json | IAM role ARN for the running container (application-level AWS permissions) — e.g. `arn:aws:iam::123456789:role/ecsTaskRole` |
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
- JDK ≥ 17 (Temurin recommended). Gradle toolchain auto-provisions
  JDK 17 via the Foojay resolver, so the host JDK version is advisory
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

## 3.1 Phase 0.5 — Clone Template Reference

Throughout Phases 2~6 the agent copies files from `examples/`, `checkstyle/`,
`spotbugs/`, `archunit/`, `docs/`, `.github/`, and other template-owned
directories. In the `--source=.` path used in Phase 0, the new repo is
empty — these files do NOT exist yet. Clone the template as a
**read-only reference**:

```bash
# Pre-cleanup: remove stale reference from previous sessions
rm -rf /tmp/ref-spring

gh repo clone llm-setup-templates/spring-template /tmp/ref-spring
```

Throughout this document, when instructed to copy from `examples/X` or
`checkstyle/`, use the `/tmp/ref-spring/` prefix:

```bash
cp /tmp/ref-spring/examples/build.gradle.kts .
cp /tmp/ref-spring/examples/settings.gradle.kts .
cp -r /tmp/ref-spring/checkstyle .
cp -r /tmp/ref-spring/spotbugs .
cp -r /tmp/ref-spring/archunit .
```

Clean up after Phase 8:

```bash
rm -rf /tmp/ref-spring
```

> **Alternative (`--template` path)**: If you started with
> `gh repo create --template ...` instead of Phase 0's `--source=.`, the
> template files are already in your repo and Phase 0.5 is not needed.
> However, the `--template` path has a drawback: GitHub auto-creates an
> "Initial commit" message that violates the Conventional Commits gate
> in Phase 8. For LLM autonomous flows, **`--source=.` (Phase 0) is the
> recommended path**.

---

## 4. Phase 1 — Spring Initializr Scaffolding

```bash
curl -G https://start.spring.io/starter.zip \
  -d type=gradle-project-kotlin \
  -d language=java \
  -d bootVersion=3.5.0 \
  -d javaVersion=17 \
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
# On Windows, the file must be staged before update-index can set the bit.
git add gradlew
git update-index --chmod=+x gradlew
```

> **Spring Boot version note**: `start.spring.io` enforces a rolling
> compatibility window. As of 2026-04-14 the minimum accepted is 3.5.0
> (earlier versions return HTTP 400 `Invalid Spring Boot version,
> compatibility range is >=3.5.0`). Check the current minimum with:
> `curl -s https://start.spring.io/metadata/client | jq -r '.bootVersion.default'`

---

## 5. Phase 2 — DevDeps (build.gradle.kts 수정)

### 5.1 Replace build.gradle.kts

`examples/build.gradle.kts` is a **full replacement**, not a merge target.
It contains the complete configuration (plugins, repositories, dependencies,
Java toolchain, Checkstyle/SpotBugs/spring-java-format tasks). Overwrite
the Spring Initializr-generated file entirely:

```bash
cp /tmp/ref-spring/examples/build.gradle.kts .
```

### 5.2 Replace settings.gradle.kts

The Spring Initializr-generated `settings.gradle.kts` does NOT include
the `foojay-resolver-convention` plugin, so Gradle cannot auto-provision
JDK 17 on machines where it isn't installed. Overwrite with the
template version:

```bash
cp /tmp/ref-spring/examples/settings.gradle.kts .
```

### 5.3 Verify Gradle can resolve JDK

```bash
./gradlew --version
# First run downloads Gradle wrapper + JDK 17 via Foojay (~200MB, 1-2 min)
```

Key additions that the template `build.gradle.kts` includes over the generated file:

**plugins block — add after spring boot plugin:**
```kotlin
id("checkstyle")
id("com.github.spotbugs") version "6.0.26"
id("io.spring.javaformat") version "0.0.47"
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
  - **Fix package declaration**: the template file uses `com.example.config`; replace `com.example` with your actual base package:
    `sed -i 's/^package com\.example/package com.example.{{PROJECT_NAME_LOWER}}/' src/main/java/.../AppProperties.java`
  - Add `@EnableConfigurationProperties(AppProperties.class)` to your main `*Application.java`

### 6.X AWS placeholder replacement

Before Phase 5.5's `validate.sh`, ensure `aws/task-definition.json`
has no remaining `{{...}}` placeholders. Required replacements:

| Placeholder | Example value |
|-------------|---------------|
| {{AWS_ACCOUNT_ID}} | `123456789012` |
| {{AWS_REGION}} | `us-east-1` |
| {{TASK_EXECUTION_ROLE_ARN}} | `arn:aws:iam::...` |
| {{TASK_ROLE_ARN}} | `arn:aws:iam::...` |
| {{SECRET_ARN_DB_USER}} | `arn:aws:secretsmanager:...` |
| {{SECRET_ARN_DB_PASSWORD}} | `arn:aws:secretsmanager:...` |
| {{RDS_ENDPOINT}} | `mydb.xxxxxx.us-east-1.rds.amazonaws.com` |
| {{DB_NAME}} | `myapp` |
| {{PROJECT_NAME}} | your repo name |

For LLM autonomous flows without real AWS resources, placeholder-like
dummy ARNs (e.g., `arn:aws:iam::000000000000:role/dummy`) satisfy `validate.sh`
structure checks while failing real AWS deployment — acceptable for CI-green
purposes.

---

## 7. Phase 4 — Gradle Tasks

Verify these tasks are available after Phase 2:
```bash
./gradlew tasks | grep -E "checkFormat|format|checkstyleMain|spotbugsMain|bootJar"
```

Expected output includes: `checkFormat`, `format`, `checkstyleMain`, `checkstyleTest`, `spotbugsMain`, `bootJar`

---

## 8. Phase 5 — CI Workflow

Copy `examples/ci.yml` → `.github/workflows/ci.yml`

Copy `examples/dependabot.yml` → `.github/dependabot.yml` (derived repo Dependabot config snapshot)

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

## 8.5 Phase 5.5 — Documentation Scaffold

This phase installs the documentation tree and GitHub governance files.

### How installation works

When a project is created with `gh repo create --template
llm-setup-templates/spring-template` (or by forking this repo), the
following are **already present in the working directory**:

```
.github/
├── ISSUE_TEMPLATE/{feature,bug,adr,config}.yml
├── PULL_REQUEST_TEMPLATE.md
├── CODEOWNERS                          # placeholder — customize
└── workflows/validate.yml

docs/
├── README.md                           # decision tree + navigation
├── requirements/
│   ├── RTM.md
│   └── _FR-template.md                 # Mini-Spec (Java / Bean Validation / JPA idiom)
├── architecture/
│   ├── overview.md                     # C4 Lv1 (Core)
│   ├── containers.md                   # C4 Lv2 (Extended — Spring Boot / JPA / Redis)
│   ├── DFD.md                          # Data Flow Diagram (Extended)
│   └── decisions/
│       ├── README.md
│       ├── _ADR-template.md
│       └── _RFC-template.md
├── reports/                            # opt-in module
│   ├── README.md
│   ├── _spike-test-template.md
│   ├── _benchmark-template.md
│   ├── _api-analysis-template.md
│   └── _paar-template.md
├── briefings/                          # opt-in module
│   ├── README.md
│   └── _template/
└── data/
    └── dictionary.md                   # Extended — links entries to JPA entities
```

The agent's job is not to generate these files — they ship with the
template. The agent's job is to **trim modules the human doesn't want**,
customize **placeholders**, and then register the decision.

### 8.5.1 Module selection

The docs/ structure has 4 modules: core (always), reports, briefings, extended.

**In autonomous/LLM mode** (default for this template): use `core` only.
Skip trimming the other modules if they don't exist yet (valid under the
`--source=.` path — docs/ is entirely absent).

**In interactive mode**: ask the human to confirm:

```
Documentation modules to keep (default = core only):
- core       [always kept]  FR / RTM / ADR / RFC / overview
- reports    [y/n]          portfolio / spike / benchmark / API / PAAR
- briefings  [y/n]          dated, frozen interview & talk archives
- extended   [y/n]          C4 Lv2 containers / DFD / Extended DD (JPA links)
```

| Module | Default | Include condition |
|--------|---------|-------------------|
| core | YES | always |
| reports | NO | user confirms OR `--with-reports` flag |
| briefings | NO | user confirms OR `--with-briefings` flag |
| extended | NO | user confirms OR `--with-extended` flag |

**Source-mode note**: Under Phase 0 `--source=.`, docs/ is empty —
copy from `/tmp/ref-spring/docs/core/` in core-only mode (see Phase 0.5).
If you started from `--template`, docs/ is pre-populated and 5.5 becomes
trim-only.

### 8.5.2 Trim unwanted modules

```bash
# If reports is NOT wanted:
rm -rf docs/reports/

# If briefings is NOT wanted:
rm -rf docs/briefings/

# If extended is NOT wanted:
rm -f docs/architecture/containers.md docs/architecture/DFD.md
rm -rf docs/data/
```

### 8.5.3 Replace placeholders

Files with placeholders to edit after template instantiation:

- `.github/CODEOWNERS` — replace `@YOUR_ORG/*` with real team handles
  (or a single `* @YOUR_USERNAME` line for solo projects)
- `docs/README.md` — top-of-file project name and one-line description
- `docs/architecture/overview.md` — project name, actors, external
  systems in the Mermaid diagram
- `docs/architecture/containers.md` (if kept) — adjust container names
  for your deployment shape (drop the Worker or Cache row if unused)
- `docs/requirements/RTM.md` — remove the example row; the table
  starts empty

### 8.5.4 Update the documentation map

Edit `.claude/rules/documentation.md` to remove module sections that
aren't installed. This keeps Claude's decision tree accurate when it
later asks "where does this new document go?"

### 8.5.5 validate.yml — template-only (do NOT copy)

`llm-setup-templates/spring-template/.github/workflows/validate.yml` is
the **template's own regression CI** — it verifies that validate.sh
continues to find all required files as the template evolves. This
workflow and `validate.sh` belong to the template repo only; **do not
copy either to your derived repo**.

When copying `.github/` contents from `/tmp/ref-spring/.github/` during
Phase 5.5, explicitly exclude:

```bash
cp -r /tmp/ref-spring/.github/ISSUE_TEMPLATE .github/
cp /tmp/ref-spring/.github/PULL_REQUEST_TEMPLATE.md .github/
cp /tmp/ref-spring/.github/CODEOWNERS .github/
# Note: .github/workflows/validate.yml — SKIP (template-only)
# Your derived repo has its own .github/workflows/ci.yml from Phase 5
```

If you mistakenly copied validate.yml, remove it:

```bash
rm -f .github/workflows/validate.yml
git add .github/workflows/
```

### 8.5.6 Self-check

Run `bash validate.sh`. The extended validation now covers:

- regression guards for PR #6's Java 17 / spring-java-format 0.0.47 fixes
- `.github/` and `docs/` Core file presence
- ADR lifecycle (five states) encoded in the decisions README
- PR template carries FR / ADR / RTM / Balancing disciplines
- Reports / Briefings / Extended modules are complete when present
  (partial installs are rejected)

---

## 9. Phase 6 — CodeRabbit Setup

1. Copy `examples/.coderabbit.yaml` → `.coderabbit.yaml`
2. Install CodeRabbit GitHub App: https://github.com/apps/coderabbitai
3. If CodeRabbit trial is unavailable, fall back to the Claude Code Review
   Action (Appendix § Fallback).

---

## 10. Phase 7 — Local Verify (fail-fast)

### 10.0 Preflight: format before verify

Run `./gradlew format` once before the verify loop. The Spring Initializr
scaffold often doesn't match spring-java-format on import order; running
`format` first avoids a guaranteed Gate-1 failure later:

```bash
./gradlew format
```

(This replaces the need to retry after `checkFormat` fails. Troubleshooting
row "checkFormat fails on import order" remains as a fallback.)

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

| Symptom | Cause | Fix |
|---------|-------|-----|
| `java -version` doesn't show 17 | JDK 11/8 is first on PATH | Proceed as-is — Gradle toolchain will auto-download JDK 17. For faster first build: `sdk use java 17.x-tem` or reset `JAVA_HOME` |
| Gradle toolchain download fails (Foojay API unreachable) | Corporate firewall / proxy | Configure the proxy in `~/.gradle/gradle.properties`, or install JDK 17 locally |
| `./gradlew: Permission denied` (CI exits 126) | Windows git did not track the gradlew exec bit | Run `git update-index --chmod=+x gradlew && git commit` — `chmod +x` alone is not enough (Windows drops the bit on commit) |
| `checkFormat` keeps failing with no diff | Silent format-vs-check disagreement between spring-java-format 0.0.43 and Gradle 8.14 | Pin the plugin to 0.0.47 or later (this template pins 0.0.47) |
| `checkFormat` fails, reason unclear | Non-ASCII Unicode in Java files (box-drawing `──`, em-dash `—`) | ASCII-only in source; remove Unicode from comments |
| Checkstyle error: `Unable to find .../config/checkstyle/suppressions.xml` | `configDirectory` unset — Gradle defaults to `config/checkstyle/` | Add `checkstyle { configDirectory.set(file("checkstyle")) }` |
| `FileTabCharacter` 86+ errors | spring-java-format tab indentation vs Google Java Style no-tab conflict | Add `<suppress checks="FileTabCharacter" files=".*\.java"/>` to `suppressions.xml` |
| ArchUnit: `Rule ... failed to check any classes` | ArchUnit 1.4+ defaults `archRule.failOnEmptyShould=true` | Set `archRule.failOnEmptyShould=false` in `src/test/resources/archunit.properties` |
| `layeredArchitecture` error: `Layer 'Controller' is empty` | Empty day-0 scaffold | Use `Architectures.layeredArchitecture().withOptionalLayers(true)` |
| `cannot find symbol: interfaces()` | `ArchRuleDefinition.interfaces()` does not exist | Replace with `classes().that()....and().areInterfaces()` |
| `start.spring.io` HTTP 400 `Invalid Spring Boot version` | Template's pinned version is outside the supported window | Use 3.5.0 or newer; verify the current floor with `curl -s https://start.spring.io/metadata/client \| jq -r '.bootVersion.default'` |
| `checkFormat` fails on import order | spring-java-format ImportOrder conflict | `./gradlew format` to auto-fix, then re-verify |
| SpotBugs NullPointerException false positive | Spring's DI pattern not recognized by the analyzer | Add `NP_NULL_ON_SOME_PATH_FROM_RETURN_VALUE` to `spotbugs/spotbugs-exclude.xml` |
| Testcontainers: `Cannot connect to Dockerd` | Docker not available | CI's `ubuntu-latest` image has Docker preinstalled. Locally, ensure Docker Desktop is running |

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
| Java (Temurin) | 17 | Spring Boot 3.2+ baseline. Gradle toolchain auto-provisions via Foojay; host JDK version does not matter |
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
- `examples/archunit/ArchitectureTest.java` — 12-rule ArchUnit test (Rule 1~6 + Rule 5 분화 3개 + Rule 7~10 multi-module boundary)
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

### § Coverage Threshold Adjustment

The JaCoCo baseline in `examples/build.gradle.kts` is pinned at **70% line + 70% branch** (see ADR-001). Raise it once the project satisfies any of the following:

| Trigger | Recommended threshold |
|---|---|
| Team grows to ≥ 5 engineers | 75-80% line + branch |
| Codebase enters audit scope (SOC2 / ISO / internal governance) | 80% line + branch |
| Production deployment active | 80% line + 70% branch |

To raise: edit `examples/build.gradle.kts` violationRules and change `minimum = "0.70".toBigDecimal()` to `minimum = "0.80".toBigDecimal()` for each `counter` block.

Do not lower below 70% without recording an ADR supersede.
