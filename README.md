# spring-template

> LLM-agent-driven Spring Boot 3 project scaffolding template.
> Hand `SETUP.md` to Claude Code / Cursor and get a green CI pipeline on GitHub.

[![CI](https://github.com/{{OWNER}}/spring-template/actions/workflows/ci.yml/badge.svg)](https://github.com/{{OWNER}}/spring-template/actions/workflows/ci.yml)
[![CodeRabbit](https://img.shields.io/badge/CodeRabbit-Active-brightgreen)](https://coderabbit.ai)
[![License](https://img.shields.io/badge/License-Apache--2.0-blue)](LICENSE)

## Why this template exists

Spring Boot 3 + Java 21 + Gradle Kotlin DSL is the 2026 production baseline,
yet most team starters omit ArchUnit, SpotBugs, and CodeRabbit — leaving
architecture drift undetected until code review. This template wires all
four static analysis tools (spring-java-format / Checkstyle / SpotBugs /
ArchUnit) into a single fail-fast CI pipeline so that an LLM agent can
scaffold a green project in one shot.

Reference: team-dodn/spring-boot-java-template fork (KWONSEOK02) analyzed
in `CHECKMATE-BACKEND-AUDIT.md`. CheckMate backend (checkmate-smu/checkmate-web-backend)
used as real-world baseline: it already uses Checkstyle + SpotBugs + ArchUnit but
omits springdoc, commitlint, Dockerfile, and ECS task-definition — all added here.

## Who is this for
- Developers using Claude Code / Cursor who want reproducible Spring Boot scaffolding
- Student teams starting from scratch with 2026 CI best practices
- Teams migrating from Groovy DSL or missing static analysis tools

## Quick Start
1. Fork or clone this template
2. Open it in Claude Code / Cursor
3. Ask: "Please set up a new Spring Boot project using SETUP.md"
4. The agent executes Phase 0 → Phase 8 and pushes to GitHub

## What's Inside
- `SETUP.md` — 14-phase setup prompt (Spring Initializr → CI green)
- `CHECKMATE-BACKEND-AUDIT.md` — real-world CheckMate backend analysis (6-section delta)
- `CLAUDE.md` — base CLAUDE.md for the generated project
- `_dot-claude/rules/` — code-style, git-workflow, architecture (ArchUnit), verification-loop
- `_dot-claude/skills/claude-md-reviewer/` — English skill for reviewing CLAUDE.md quality
- `examples/` — ready-to-copy config files (build.gradle.kts, checkstyle, Dockerfile, etc.)
- `CODERABBIT-PROMPT-GUIDE.md` — how to author `.coderabbit.yaml` path_instructions

> **Note on `_dot-claude/`:** These files should be copied to `.claude/` in the
> generated project. The `_dot-claude/` staging directory is used here because
> `.claude/` is a protected namespace in the template itself.
> ```bash
> cp -r _dot-claude/ .claude/
> ```

## Scaling Path — Multi-Module (team-dodn pattern)

This template starts single-module. When the project grows:

```
# Current (single-module)
com.example.{controller,service,repository,domain,dto,config}

# Scaled (multi-module — team-dodn pattern)
settings.gradle.kts:
  include("core:core-api")       # was ..controller.. + ..service..
  include("storage:db-core")     # was ..repository.. + ..domain..
  include("clients:clients-*")   # external API integrations
  include("support:logging")     # cross-cutting concerns

ArchUnit rule 6 already enforces the package boundaries.
Migration = Gradle settings change + move packages.
```

Reference: [team-dodn/spring-boot-java-template](https://github.com/team-dodn/spring-boot-java-template)

## Phase Overview (14 sections in SETUP.md)

1. Preface + LLM meta-instructions + Placeholder Index
2. Prerequisites (gh, git, JDK 21, curl, Docker)
3. Phase 0 — Repo Init (gh repo create)
4. Phase 1 — Spring Initializr (Gradle Kotlin DSL, Java 21)
5. Phase 2 — DevDeps (Checkstyle, SpotBugs, spring-java-format, springdoc, ArchUnit, Testcontainers)
6. Phase 3 — Config Files (checkstyle.xml, Dockerfile, docker-compose.yml, AppProperties.java, etc.)
7. Phase 4 — Gradle Tasks verification
8. Phase 5 — CI Workflow (commitlint → format → checkstyle → spotbugs → test → build)
9. Phase 6 — CodeRabbit Setup
10. Phase 7 — Local Verify (./gradlew + Docker smoke test)
11. Phase 8 — First Push + CI Green (Git Safety Gate)
12. Troubleshooting (5 common issues)
13. Essential Checklist
14. Config Reference Appendix (pinned versions, CI reference, CodeRabbit reference)

## Static Analysis Stack

| Tool | Purpose | Enforced |
|------|---------|---------|
| spring-java-format | Whitespace, import ordering | `./gradlew checkFormat` + CI |
| Checkstyle 10.17.0 | Naming, braces, line length | `./gradlew checkstyleMain` + CI |
| SpotBugs 4.8.6 | Bug patterns, null safety | `./gradlew spotbugsMain` + CI |
| ArchUnit 1.3.0 | 6-rule layered architecture | `./gradlew test` (ArchUnit runs as JUnit) |
| CodeRabbit | PR review (7 Spring-specific items) | Automatic on every PR |
| commitlint | Conventional Commits on PR | `wagoid/commitlint-github-action@v6` in CI |

## License
Apache-2.0
