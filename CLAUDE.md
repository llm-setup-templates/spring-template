# {{PROJECT_NAME}}

> Generated from llm-setup-prompts/spring-template.

## Project Overview
{{PROJECT_ONE_LINER}}

## Tech Stack
- Language: Java 21 (LTS / Temurin)
- Package Manager: Gradle (Kotlin DSL 8.x)
- Formatter: spring-java-format 0.0.43
- Linter: Checkstyle 10.17.0 (Google Java Style) + SpotBugs 4.8.6
- Type Checker: javac (via ./gradlew compileJava — integrated in build)
- Test Runner: JUnit 5 + AssertJ + Mockito + Testcontainers
- CI: GitHub Actions
- PR Review: CodeRabbit

## Primary Commands
- Install deps: `./gradlew dependencies`
- Format check: `./gradlew applyFormat` (auto-fix) / `./gradlew checkFormat` (check only)
- Lint: `./gradlew checkstyleMain checkstyleTest`
- Type check: `./gradlew compileJava compileTestJava`
- Test: `./gradlew test`
- Build: `./gradlew build bootJar`
- Full verify: `./gradlew checkFormat checkstyleMain checkstyleTest spotbugsMain test build`

## Architecture Summary
See `.claude/rules/architecture.md` for full rules.
This project uses a 3-layer Spring Boot architecture (Controller → Service → Repository) enforced by ArchUnit (6 rules) running as part of `./gradlew test`. All classes live within `com.example.*` from day one, matching the package boundaries needed for a future multi-module split (team-dodn pattern: core/clients/storage/support). DTOs must never carry JPA annotations; domain entities must never be returned directly from controllers.

## Verification Rules
After any code change, run the full verification loop.
Never declare a task complete until it passes.
See `.claude/rules/verification-loop.md`.

## Git Workflow
- Never commit directly to `main`
- Conventional Commits required
- See `.claude/rules/git-workflow.md`

## Business / Domain Terms
N/A — add project-specific terms here as the codebase evolves.
