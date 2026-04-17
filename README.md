# Spring Boot Template — LLM-Agent-Ready Scaffolding

[한국어 README](./README.ko.md)

> An opinionated Spring Boot 3 + Java 17 (Temurin LTS) + Gradle KTS template
> designed for LLM coding agents (Claude Code / Cursor) to scaffold from an
> empty directory to a green GitHub Actions CI — without human intervention
> mid-setup.

**Empirically verified**: SETUP.md alone drives Claude Code → green CI in under 3 min
([proof run](https://github.com/KWONSEOK02/llm-setup-e2e17-spring/actions/runs/24565850331), 2m53s).

---

## Why this template exists

Spring Boot has a hundred ways to set up a project. This template picks **one
defensible answer per layer** and ships a SETUP.md the LLM agent executes
top-to-bottom.

**Pinned choices** (with reasoning):

| Layer | Choice | Why (rejected alternatives) |
|---|---|---|
| Java | 17 (Temurin LTS, Foojay auto-provisioned) | 11/21 both valid, but 17 is current LTS majority; Foojay means host JDK version doesn't matter |
| Build | Gradle Kotlin DSL 8.x | Maven's XML is verbose; Gradle Groovy DSL slowly giving way to KTS |
| Architecture | Singleton start, multi-module ready (team-dodn package naming) | Multi-module from day 1 over-engineers; "never multi-module" traps you when you scale |
| Response envelope | `ApiResponse<T>` wrapper, `CoreException` hierarchy | Raw entity return leaks JPA state to clients; `ResponseStatusException` in services breaks layering |
| Formatter | spring-java-format 0.0.47 (owns whitespace) | Checkstyle fighting Prettier-style formatting is a waste |
| Linter | Checkstyle 10.17 (Google Java Style base) + SpotBugs 4.8.6 | One for style, one for bug patterns |
| Boundary test | ArchUnit (10 layered rules) | Reflection-based checks that compile-time can't catch |
| CI commit gate | wagoid/commitlint-github-action@v6 | JVM templates can't use Husky portably — CI-level gate |

---

## Who should use this

**Persona 1 — Solo developer or small team starting a new Spring Boot service**
- Solves: "which packages? which response wrapper? which error type? which boundary check?"
- Does NOT solve: database schema design, external API integration choices

**Persona 2 — LLM-assisted development (Claude Code, Cursor)**
- Solves: SETUP.md is fail-fast, ArchUnit catches layer violations, spring-java-format auto-fixes style — the agent gets concrete red→green feedback
- Does NOT solve: business logic; the template shapes structure, not domain

**Persona 3 — Team migrating from unversioned Spring Boot conventions to a reviewable codebase**
- Solves: Checkstyle + SpotBugs + ArchUnit in CI give you concrete failures to fix one at a time
- Does NOT solve: the migration itself

**Persona 4 — Instructor setting up a reproducible Spring Boot course**
- Solves: every student has identical JDK, Gradle, plugins, CI
- Does NOT solve: curriculum

---

## Who should NOT use this

- You're on Spring Boot 2.x or Java 11 → this template pins 3.x + 17
- You want Maven → rewrite build.gradle.kts / settings.gradle.kts in pom.xml
- You need a pure library (no web layer) → the template is service-oriented (`spring-boot-starter-web`)
- You're committed to Clean Architecture / Hexagonal with ports & adapters from day 1 → this template is layered-first, CA-ready second

---

## Quick fit check

1. **Greenfield Spring Boot 3 service project?** If no → consider forking.
2. **Willing to accept layered architecture and migrate to multi-module later if needed?** If no → pick a multi-module template from day 1.
3. **OK with Gradle KTS (not Maven or Groovy)?** If no → this template requires a rewrite of the build files.

All three yes → proceed to [SETUP.md](./SETUP.md).

---

## Scaling path — singleton to multi-module

The template starts as a **single Gradle module** but uses team-dodn's package
naming convention so you can extract to Gradle submodules later without
restructuring code.

Current packages → future modules:

| Package today | Future Gradle module | Rough signal to split |
|---|---|---|
| `core.api` | `core:core-api` | > 40 files in `core/` or > 2 teams owning it |
| `core.domain` | `core:core-api` (domain subdir) | Tightly coupled to core-api; split further only with DDD |
| `core.enums` | `core:core-enum` | Shared across 3+ modules |
| `storage.db` | `storage:db-core` | Multiple storage backends emerge |
| `clients.*` | `clients:client-*` | 3+ distinct external APIs with different SLOs |
| `support.*` | `support:logging`, `support:monitoring` | When you need to publish reusable utility jars |

**When to split?** The anti-pattern is splitting too early. Stay singleton until:
- Compile time > 2 min and you can identify a subtree that's rarely edited
- Two teams are blocking each other's CI through single-module test times
- You need to publish a subset (e.g., `core.enums`) as a reusable library

ArchUnit rules carry over unchanged when you split — they enforce package
boundaries, and `./gradlew :core-api:test` runs the same ArchUnit checks against
the extracted module.

---

## What's inside

- Setup flow: [SETUP.md](./SETUP.md)
- AI agent rules: [CLAUDE.md](./CLAUDE.md)
- Architecture (layer rules, ArchUnit): [.claude/rules/architecture.md](./.claude/rules/architecture.md)
- Verification loop (Gradle task sequence): [.claude/rules/verification-loop.md](./.claude/rules/verification-loop.md)
- Test modification rules: [.claude/rules/test-modification.md](./.claude/rules/test-modification.md)
- Ready-to-copy config files: [examples/](./examples/)

---

## Related templates

- [python-template](https://github.com/llm-setup-templates/python-template) — Python 3.13 + 3 archetypes
- [typescript-template](https://github.com/llm-setup-templates/typescript-template) — Next.js 15 + FSD 5 layers

---

## License

Apache-2.0
